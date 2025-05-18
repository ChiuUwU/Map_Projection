from flask import Flask, request, jsonify
from flask_cors import CORS
import matlab.engine
import requests
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

app = Flask(__name__)
CORS(app)

print("\U0001F680 启动 Matlab 引擎中...")
eng = matlab.engine.start_matlab()
eng.eval("clear functions", nargout=0)
eng.eval("rehash", nargout=0)
eng.cd(r'D:\Desktop\Code\PyCharm\Map_Projection\backend')
print("✅ Matlab 已启动")

def matlab_to_list(val):
    if isinstance(val, matlab.double):
        return [list(x) for x in val] if hasattr(val, '__len__') and isinstance(val[0], matlab.double) else list(val._data)
    elif isinstance(val, list):
        return [matlab_to_list(v) for v in val]
    return val

@app.route('/api/project', methods=['POST'])
def project():
    try:
        data = request.get_json()
        projection = data.get("projection", "mercator")
        geometry = data['features'][0]['geometry']
        coords_all = []

        if geometry['type'] == 'Polygon':
            coords_all = geometry['coordinates']
        elif geometry['type'] == 'MultiPolygon':
            for polygon in geometry['coordinates']:
                coords_all.extend(polygon)
        else:
            return jsonify({'error': '不支持的几何类型'}), 400

        print(f"✅ 区域数：{len(coords_all)} ，投影方式：{projection}")

        lon_cell, lat_cell = [], []
        for ring in coords_all:
            lons = [float(p[0]) for p in ring]
            lats = [float(p[1]) for p in ring]
            lon_cell.append(matlab.double(lons))
            lat_cell.append(matlab.double(lats))

        # 将 projection 映射为 Matlab 内部识别的值
        projection_map = {
            'azimuthal_conformal': 'azimuthal_conformal',
            'azimuthal_equal_area': 'azimuthal_equal_area',
            'azimuthal_equidistant': 'azimuthal_equidistant',
            'azimuthal_perspective': 'azimuthal_perspective',
            'conic_conformal': 'conic_conformal',
            'conic_equal_area': 'conic_equal_area',
            'conic_equidistant': 'conic_equidistant',
            'conic_oblique': 'conic_oblique',
            'cylindrical_conformal': 'cylindrical_conformal',
            'cylindrical_equal_area': 'cylindrical_equal_area',
            'cylindrical_equidistant': 'cylindrical_equidistant',
            'cylindrical_oblique': 'cylindrical_oblique',
            'cylindrical_perspective': 'cylindrical_perspective',
            'gauss_kruger': 'gauss_kruger',
            'pseudo_azimuthal': 'pseudo_azimuthal',
            'pseudo_cylindrical': 'pseudo_cylindrical',
            'pseudo_conic': 'pseudo_conic'
        }

        if projection not in projection_map:
            return jsonify({'error': f'未知的投影类型: {projection}'}), 400

        projection_key = projection_map[projection]

        x_distorted, y_distorted, x_baseline, y_baseline, area_original, area_projected = eng.project_with_baseline(
            lon_cell, lat_cell, projection_key, nargout=6
        )
        # 使用原始 lon_cell / lat_cell 作为 x_base/y_base
        return jsonify({
            'x': matlab_to_list(x_distorted),
            'y': matlab_to_list(y_distorted),
            'x_base': matlab_to_list(lon_cell),
            'y_base': matlab_to_list(lat_cell),
            'area_original': float(area_original),
            'area_projected': float(area_projected)
        })

    except Exception as e:
        print("❌ 发生错误:", str(e))
        return jsonify({'error': str(e)}), 500

@app.route('/api/explain', methods=['POST'])
def explain_projection():
    data = request.get_json()

    # 计算面积比
    try:
        ratio = data['area_projected'] / data['area_original']
    except ZeroDivisionError:
        ratio = 1.0

    # 构造 prompt
    prompt = f"""
你是一位地图投影专家，请根据以下信息，撰写一段180～200字的中文说明，用于解释地图投影带来的面积变形现象：

国家：{data['country']}
投影方式：{data['projection']}
原始面积：{data['area_original']:.2f} 万平方公里
投影后面积：{data['area_projected']:.2f} 万平方公里
面积变化倍数：{ratio:.2f} 倍

说明需涵盖以下三点（但无需用小标题）：
1. 该国家在此投影图上的面积变化情况；
2. 造成这种面积变形的投影机制和地理原理（包括纬度、保角、保面积等特性）；
3. 此投影适合的使用场景与其局限性。

要求：
- 使用自然语言表达，语言清晰、具有逻辑性；
- 控制在150～180字左右；
- 不使用比喻或举例，不涉及其他国家；
- 不需解释地图学基础，仅针对当前国家与投影现象展开。

"""

    headers = {
        "Authorization": f"Bearer {os.getenv('DEEPSEEK_API_KEY')}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "deepseek-chat",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7
    }

    res = requests.post("https://api.deepseek.com/v1/chat/completions", headers=headers, json=payload)

    print("📤 返回原始数据：", res.text)
    print("📋 状态码：", res.status_code)

    try:
        res = requests.post("https://api.deepseek.com/v1/chat/completions", headers=headers, json=payload)
        reply = res.json()['choices'][0]['message']['content'].strip()
        return jsonify({"explanation": reply})
    except Exception as e:
        return jsonify({"error": f"AI说明生成失败：{str(e)}"})

@app.route('/api/chat', methods=['POST'])
def chat_with_context():
    import requests, os
    data = request.get_json()

    # 1. 获取上下文 context 和历史对话 history
    ctx = data.get('context', {})
    user_history = data.get('history', [])

    # 2. 构造 system prompt：传递当前国家 + 投影 + 面积 + explain
    system_prompt = f"""你是一位地图投影专家，现在正在解答关于国家「{ctx.get('country', '（未知国家）')}」在投影方式「{ctx.get('projection', '（未知投影）')}」下的地图变形问题。

该国家的真实面积为 {ctx.get('area_original', '?')} 万平方公里，
在该投影中变为 {ctx.get('area_projected', '?')} 万平方公里，
面积变化为 {ctx.get('scale_ratio', '?'):.2f} 倍。

AI 系统对该情况的说明如下：
{ctx.get('explanation', '（无说明信息）')}

你的任务是基于这些背景信息，参与一轮轮自然语言交流，用清晰、简洁的中文回答用户的问题。每次回复不超过150字，风格保持亲切自然，不要重复系统说明内容。"""

    # 3. 拼接 messages：system + chat 历史
    full_messages = [{"role": "system", "content": system_prompt}] + user_history

    # 4. 请求 DeepSeek Chat 接口
    headers = {
        "Authorization": f"Bearer {os.getenv('DEEPSEEK_API_KEY')}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "deepseek-chat",
        "messages": full_messages,
        "temperature": 0.5,
        "max_tokens": 200
    }

    try:
        res = requests.post("https://api.deepseek.com/v1/chat/completions", headers=headers, json=payload)
        print("📤 DeepSeek 返回：", res.text)  # 可选调试
        reply = res.json()['choices'][0]['message']['content'].strip()
        return jsonify({"reply": reply})
    except Exception as e:
        return jsonify({"error": f"AI对话失败：{str(e)}"})

if __name__ == '__main__':
    app.run(port=5000)


