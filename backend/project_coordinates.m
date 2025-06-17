% function [x, y] = project_coordinates(lon, lat, type, R)
%     lat_rad = deg2rad(lat);
%     lon_rad = deg2rad(lon);
% 
%     switch lower(type)
%         %% 方位投影
%         case 'azimuthal_equidistant'
%             x = R * cos(lat_rad) .* sin(lon_rad);
%             y = R * lat_rad;
% 
%         case 'azimuthal_equal_area'
%             k = sqrt(2 ./ (1 + cos(lat_rad) .* cos(lon_rad)));
%             x = R * k .* cos(lat_rad) .* sin(lon_rad);
%             y = R * k .* sin(lat_rad);
% 
%         case 'azimuthal_conformal'
%             x = 2 * R * tan((pi/4) - (lat_rad / 2)) .* sin(lon_rad);
%             y = -2 * R * tan((pi/4) - (lat_rad / 2)) .* cos(lon_rad);
% 
%         case 'azimuthal_perspective'
%             h = 2 * R; % 视点高度，可自定义
%             cos_c = cos(lat_rad) .* cos(lon_rad);
%             x = R * sin(lon_rad) ./ (1 + cos_c);
%             y = R * sin(lat_rad) ./ (1 + cos_c);
% 
%         %% 圆锥投影
%         case 'conic_conformal'
%             stdlat = deg2rad(30);
%             n = sin(stdlat);
%             rho = R * cot(stdlat) - lat_rad;
%             theta = n * lon_rad;
%             x = rho .* sin(theta);
%             y = -rho .* cos(theta);
% 
%         case 'conic_equal_area'
%             stdlat = deg2rad(30);
%             n = sin(stdlat);
%             rho = 2 * R * sqrt(1 - n^2) ./ (1 + n * sin(lat_rad));
%             theta = n * lon_rad;
%             x = rho .* sin(theta);
%             y = -rho .* cos(theta);
% 
%         case 'conic_equidistant'
%             stdlat = deg2rad(30);
%             n = sin(stdlat);
%             rho = R * (1 - n * lat_rad);
%             theta = n * lon_rad;
%             x = rho .* sin(theta);
%             y = -rho .* cos(theta);
% 
%         case 'oblique_conic'
%             stdlat = deg2rad(30);
%             n = sin(stdlat);
%             lon_shifted = lon_rad - deg2rad(30);
%             rho = R * cot(stdlat) - lat_rad;
%             theta = n * lon_shifted;
%             x = rho .* sin(theta);
%             y = -rho .* cos(theta);
% 
% 
%         %% 圆柱投影
%         case 'cylindrical_conformal'
%             lat_safe = min(max(lat_rad, -pi/2 + eps), pi/2 - eps);
%             x = R * lon_rad;
%             y = R * log(tan(pi/4 + lat_safe/2));
% 
%         case 'cylindrical_equal_area'
%             x = R * lon_rad;
%             y = R * sin(lat_rad);
% 
%         case 'cylindrical_equidistant'
%             x = R * lon_rad;
%             y = R * lat_rad;
% 
%         case 'cylindrical_oblique'
%             theta0 = deg2rad(30);  
%             lat_rot = asin(cos(theta0) .* sin(lat_rad) - sin(theta0) .* cos(lat_rad) .* sin(lon_rad));
%             lon_rot = atan2(cos(lat_rad) .* cos(lon_rad), sin(theta0) .* sin(lat_rad) + cos(theta0) .* cos(lat_rad) .* sin(lon_rad));
%             x = R * lon_rot;
%             y = R * lat_rot;
% 
%         case 'cylindrical_perspective'
%             h = 2 * R;  
%             k = h ./ (h - cos(lat_rad));  
%             x = R * lon_rad .* k;
%             y = R * lat_rad .* k;
% 
%         %% 特殊投影
%         case 'gauss_kruger'
%             k0 = 1;
%             x = R * k0 * lon_rad;
%             y = R * k0 * log(tan(pi/4 + lat_rad/2));
% 
%         case 'pseudo_azimuthal'
%             x = R * lon_rad .* cos(lat_rad);
%             y = R * lat_rad;
% 
%         case 'pseudo_cylindrical'
%             x = R * lon_rad .* cos(lat_rad);
%             y = R * lat_rad;
% 
%         case 'pseudo_conic'
%             x = R * lon_rad .* sin(lat_rad);
%             y = R * lat_rad;
% 
%         otherwise
%             error('Unsupported projection type: %s', type)
%     end
% end

% function [x, y] = project_coordinates(lon, lat, type, R)
% % PROJECT_COORDINATES 地图投影函数 - 针对中国优化
% % 输入:
% %   lon  - 经度 (度)
% %   lat  - 纬度 (度)  
% %   type - 投影类型
% %   R    - 地球半径 (默认: 6371000m)
% % 输出:
% %   x, y - 投影后的平面坐标
% 
%     % 参数验证
%     if nargin < 3
%         error('至少需要3个输入参数: lon, lat, type');
%     end
%     if nargin < 4 || isempty(R)
%         R = 6371000; % 地球半径，单位：米
%     end
% 
%     % 输入验证
%     validateattributes(lon, {'numeric'}, {'real', 'finite'}, 'project_coordinates', 'lon', 1);
%     validateattributes(lat, {'numeric'}, {'real', 'finite', '>=',-90, '<=', 90}, 'project_coordinates', 'lat', 2);
%     validateattributes(R, {'numeric'}, {'scalar', 'positive', 'finite'}, 'project_coordinates', 'R', 4);
% 
%     % 角度转弧度
%     lat_rad = deg2rad(lat);
%     lon_rad = deg2rad(lon);
% 
%     % 中国的参数设置
%     central_meridian = 105;  % 中国中央经线 105°E
%     stdlat = 35;            % 中国标准纬线 35°N
% 
%     cm_rad = deg2rad(central_meridian);
%     stdlat_rad = deg2rad(stdlat);
% 
%     % 调整经度到中国中央经线
%     lon_adj = lon_rad - cm_rad;
% 
%     switch lower(type)
%         %% 方位投影
%         case 'azimuthal_equidistant'
%             % 方位等距投影
%             c = acos(cos(lat_rad) .* cos(lon_adj));
%             k = c ./ sin(c);
%             k(c == 0) = 1; % 避免0/0
%             x = R * k .* cos(lat_rad) .* sin(lon_adj);
%             y = R * k .* sin(lat_rad);
% 
%         case 'azimuthal_equal_area'
%             % 方位等面积投影 (Lambert方位投影)
%             k = sqrt(2 ./ (1 + cos(lat_rad) .* cos(lon_adj)));
%             x = R * k .* cos(lat_rad) .* sin(lon_adj);
%             y = R * k .* sin(lat_rad);
% 
%         case 'azimuthal_conformal'
%             % 方位等角投影 (立体投影)
%             k = 2 ./ (1 + cos(lat_rad) .* cos(lon_adj));
%             x = R * k .* cos(lat_rad) .* sin(lon_adj);
%             y = R * k .* sin(lat_rad);
% 
%         case 'azimuthal_perspective'
%             % 透视投影
%             h = 2 * R; % 视点高度
%             cos_c = cos(lat_rad) .* cos(lon_adj);
%             k = (h - R) ./ (h - R * cos_c);
%             x = R * k .* cos(lat_rad) .* sin(lon_adj);
%             y = R * k .* sin(lat_rad);
% 
%         %% 圆锥投影  
%         case 'conic_conformal'
%             % 兰伯特等角圆锥投影（双标准纬线，适配中国）
%             lat1 = deg2rad(25);  % 南标准纬线（固定）
%             lat2 = deg2rad(47);  % 北标准纬线（固定）
%             lon0 = deg2rad(105); % 中央经线设为 105°E
% 
%             n = log(cos(lat1) ./ cos(lat2)) ./ ...
%                 log(tan(pi/4 + lat2/2) ./ tan(pi/4 + lat1/2));
%             F = cos(lat1) .* (tan(pi/4 + lat1/2)).^n ./ n;
%             rho = R * F ./ (tan(pi/4 + lat_rad/2)).^n;
%             rho0 = R * F ./ (tan(pi/4 + deg2rad(35.5)/2)).^n;  % 纬度中心可固定为中纬度
%             theta = n * (lon_rad - lon0);
% 
%             x = rho .* sin(theta);
%             y = rho0 - rho .* cos(theta);
% 
%         case 'conic_equal_area'
%             % 等面积圆锥投影（Albers，双标准纬线，适配中国）
%             lat1 = deg2rad(25);    % 第一标准纬线
%             lat2 = deg2rad(47);    % 第二标准纬线
%             lon0 = deg2rad(105);   % 中央经线
% 
%             n = (sin(lat1) + sin(lat2)) / 2;
%             C = cos(lat1)^2 + 2 * n * sin(lat1);
%             rho = R * sqrt(C - 2 * n * sin(lat_rad)) / n;
%             rho0 = R * sqrt(C - 2 * n * sin(deg2rad(35.5))) / n;  % 中心纬度可微调
%             theta = n * (lon_rad - lon0);
% 
%             x = rho .* sin(theta);
%             y = rho0 - rho .* cos(theta);
% 
%         case 'conic_equidistant'
%             % 等距圆锥投影
%             n = sin(stdlat_rad);
%             G = cos(stdlat_rad)/n + stdlat_rad;
%             rho = R * (G - lat_rad);
%             theta = n * lon_adj;
%             x = rho .* sin(theta);
%             y = R * G - rho .* cos(theta);
%         case 'conic_oblique'
%             % 斜轴圆锥投影（以30°为倾斜标准纬线）
%             % 设置斜轴极点（例如偏转到中国）
%             pole_lat = deg2rad(35); % 可以根据中国中部设置
%             pole_lon = deg2rad(105);
% 
%             dlon = lon_rad - pole_lon;
%             lat_oblique = asin(sin(lat_rad) .* sin(pole_lat) + ...
%                                cos(lat_rad) .* cos(pole_lat) .* cos(dlon));
%             lon_oblique = atan2(cos(lat_rad) .* sin(dlon), ...
%                                 cos(pole_lat) .* sin(lat_rad) - sin(pole_lat) .* cos(lat_rad) .* cos(dlon));
% 
%             stdlat_oblique = deg2rad(30);
%             n = sin(stdlat_oblique);
%             rho = R * cot(stdlat_oblique) - lat_oblique;
%             theta = n * lon_oblique;
% 
%             x = rho .* sin(theta);
%             y = -rho .* cos(theta);            
%         %% 圆柱投影
%         case 'mercator'
%             % 墨卡托投影 (等角圆柱投影)
%             lat_safe = sign(lat_rad) .* min(abs(lat_rad), pi/2 - 1e-10);
%             x = R * lon_adj;
%             y = R * log(tan(pi/4 + lat_safe/2));
% 
%         case 'cylindrical_equal_area'
%             % 等面积圆柱投影
%             x = R * lon_adj;
%             y = R * sin(lat_rad);
% 
%         case 'plate_carree'
%             % 等距圆柱投影 (Plate Carrée)
%             x = R * lon_adj;
%             y = R * lat_rad;
% 
%         case 'miller'
%             % 米勒投影
%             x = R * lon_adj;
%             y = R * 1.25 * log(tan(pi/4 + 0.4*lat_rad));
% 
%         %% 伪圆柱投影
%         case 'sinusoidal'
%             % 正弦投影
%             x = R * lon_adj .* cos(lat_rad);
%             y = R * lat_rad;
% 
%         case 'mollweide'
%             % Mollweide投影
%             theta = lat_rad;
%             % 迭代求解 2*theta + sin(2*theta) = pi*sin(lat)
%             for iter = 1:10
%                 dtheta = -(2*theta + sin(2*theta) - pi*sin(lat_rad)) ./ (2 + 2*cos(2*theta));
%                 theta = theta + dtheta;
%                 if max(abs(dtheta)) < 1e-10
%                     break;
%                 end
%             end
%             x = R * 2*sqrt(2)/pi * lon_adj .* cos(theta);
%             y = R * sqrt(2) * sin(theta);
% 
%         case 'robinson'
%             % Robinson投影 (简化版本)
%             phi_deg = abs(rad2deg(lat_rad));
%             % 简化的多项式逼近
%             AA = [1.0000, 0.9986, 0.9954, 0.9900, 0.9822, 0.9730, 0.9600, 0.9427, 0.9216, 0.8962, 0.8679, 0.8350, 0.7986, 0.7597, 0.7186, 0.6732, 0.6213, 0.5722, 0.5322];
%             BB = [0.0000, 0.0620, 0.1240, 0.1860, 0.2480, 0.3100, 0.3720, 0.4340, 0.4958, 0.5571, 0.6176, 0.6769, 0.7346, 0.7903, 0.8435, 0.8936, 0.9394, 0.9761, 1.0000];
% 
%             idx = max(1, min(19, floor(phi_deg/5) + 1));
%             A = AA(idx);
%             B = BB(idx);
% 
%             x = R * 0.8487 * A .* lon_adj;
%             y = R * 1.3523 * B .* sign(lat_rad);
% 
%         %% UTM投影
%         case 'utm'
%             % UTM投影 (简化版本)
%             k0 = 0.9996;
%             e = 0.0818191908426; % WGS84椭球偏心率
%             e_prime2 = e^2 / (1 - e^2);
% 
%             N = R ./ sqrt(1 - e^2 * sin(lat_rad).^2);
%             T = tan(lat_rad).^2;
%             C = e_prime2 * cos(lat_rad).^2;
%             A_coeff = cos(lat_rad) .* lon_adj;
% 
%             M = R * ((1 - e^2/4 - 3*e^4/64) * lat_rad - ...
%                      (3*e^2/8 + 3*e^4/32) * sin(2*lat_rad) + ...
%                      (15*e^4/256) * sin(4*lat_rad));
% 
%             x = k0 * N .* (A_coeff + (1-T+C) .* A_coeff.^3/6 + ...
%                           (5-18*T+T.^2+72*C-58*e_prime2) .* A_coeff.^5/120);
%             y = k0 * (M + N .* tan(lat_rad) .* (A_coeff.^2/2 + ...
%                      (5-T+9*C+4*C.^2) .* A_coeff.^4/24 + ...
%                      (61-58*T+T.^2+600*C-330*e_prime2) .* A_coeff.^6/720));
% 
%         %% 高斯-克吕格投影
%         case 'gauss_kruger'
%             % 高斯-克吕格投影 (中国常用)
%             k0 = 1;
%             e = 0.0818191908426; % WGS84椭球偏心率
%             e_prime2 = e^2 / (1 - e^2);
% 
%             N = R ./ sqrt(1 - e^2 * sin(lat_rad).^2);
%             T = tan(lat_rad).^2;
%             C = e_prime2 * cos(lat_rad).^2;
%             A_coeff = cos(lat_rad) .* lon_adj;
% 
%             M = R * ((1 - e^2/4 - 3*e^4/64) * lat_rad - ...
%                      (3*e^2/8 + 3*e^4/32) * sin(2*lat_rad) + ...
%                      (15*e^4/256) * sin(4*lat_rad));
% 
%             x = k0 * N .* (A_coeff + (1-T+C) .* A_coeff.^3/6 + ...
%                           (5-18*T+T.^2+72*C-58*e_prime2) .* A_coeff.^5/120);
%             y = k0 * (M + N .* tan(lat_rad) .* (A_coeff.^2/2 + ...
%                      (5-T+9*C+4*C.^2) .* A_coeff.^4/24 + ...
%                      (61-58*T+T.^2+600*C-330*e_prime2) .* A_coeff.^6/720));
% 
%         otherwise
%             error('不支持的投影类型: %s\n支持的投影类型包括:\n%s', type, ...
%                   sprintf(['azimuthal_equidistant, azimuthal_equal_area, azimuthal_conformal,\n' ...
%                           'azimuthal_perspective, conic_conformal, conic_equal_area, conic_equidistant,\n' ...
%                           'mercator, cylindrical_equal_area, plate_carree, miller,\n' ...
%                           'sinusoidal, mollweide, robinson, utm, gauss_kruger']));
%     end
% 
%     % 确保输出与输入具有相同的维度
%     if isscalar(lon) && isscalar(lat)
%         x = double(x);
%         y = double(y);
%     end
% end
% 
% % 辅助函数：角度转弧度
% function rad = deg2rad(deg)
%     rad = deg * pi / 180;
% end
% 
% % 辅助函数：弧度转角度
% function deg = rad2deg(rad)
%     deg = rad * 180 / pi;
% end
function [x, y] = project_coordinates(lon, lat, type, R)
% PROJECT_COORDINATES 全球适配地图投影函数
% 输入:
%   lon  - 经度数组 (度)
%   lat  - 纬度数组 (度)
%   type - 投影类型（字符串）
%   R    - 地球半径（单位米，默认6371000）
% 输出:
%   x, y - 投影后的平面坐标（米）

    if nargin < 4
        R = 6371000;
    end

    % 自动计算中心点
    center_lon = mean(lon(:));
    center_lat = mean(lat(:));
    center_lon_rad = deg2rad(center_lon);
    center_lat_rad = deg2rad(center_lat);
    stdlat_rad = deg2rad(center_lat); % 默认标准纬线设为中心纬度

    % 坐标转弧度并调整经度差
    lat_rad = deg2rad(lat);
    lon_rad = deg2rad(lon);
    lon_adj = lon_rad - center_lon_rad;

    switch lower(type)
        %% 方位投影
        case 'azimuthal_equidistant'
            phi0 = center_lat_rad;
            lambda0 = center_lon_rad;
            delta_lambda = lon_rad - lambda0;
        
            cos_c = sin(phi0) .* sin(lat_rad) + ...
                    cos(phi0) .* cos(lat_rad) .* cos(delta_lambda);
        
            % 防止 cos_c 为 -1 导致除零（投影极点对跖点）
            cos_c = max(min(cos_c, 1), -1 + 1e-10);
        
            k = 2 ./ (1 + cos_c);
            x = R * k .* cos(lat_rad) .* sin(delta_lambda);
            y = R * k .* (cos(phi0) .* sin(lat_rad) - ...
                  sin(phi0) .* cos(lat_rad) .* cos(delta_lambda));
        case 'azimuthal_equal_area'
            k = sqrt(2 ./ (1 + cos(lat_rad) .* cos(lon_adj)));
            x = R * k .* cos(lat_rad) .* sin(lon_adj);
            y = R * k .* sin(lat_rad);

        case 'azimuthal_conformal'
            x = 2 * R * tan((pi/4) - (lat_rad / 2)) .* sin(lon_adj);
            y = -2 * R * tan((pi/4) - (lat_rad / 2)) .* cos(lon_adj);

        case 'azimuthal_perspective'
            phi0 = center_lat_rad;
            lambda0 = center_lon_rad;
            delta_lambda = lon_rad - lambda0;
            
            cos_c = sin(phi0) .* sin(lat_rad) + cos(phi0) .* cos(lat_rad) .* cos(delta_lambda);
            cos_c = min(max(cos_c, -1), 1);  % 防止精度溢出
            
            h = 1.5 * R;  % 建议不要设太高（比 2R 更稳）
            k = (h - R) ./ (h - R * cos_c);
            
            x = R * k .* cos(lat_rad) .* sin(delta_lambda);
            y = R * k .* (cos(phi0) .* sin(lat_rad) - ...
                          sin(phi0) .* cos(lat_rad) .* cos(delta_lambda));

        %% 圆锥投影
        case 'conic_conformal'
            lat1 = deg2rad(center_lat - 10);
            lat2 = deg2rad(center_lat + 10);
            n = log(cos(lat1) ./ cos(lat2)) ./ ...
                log(tan(pi/4 + lat2/2) ./ tan(pi/4 + lat1/2));
            F = cos(lat1) .* (tan(pi/4 + lat1/2)).^n ./ n;
            rho = R * F ./ (tan(pi/4 + lat_rad/2)).^n;
            rho0 = R * F ./ (tan(pi/4 + center_lat_rad/2)).^n;
            theta = n * lon_adj;
            x = rho .* sin(theta);
            y = rho0 - rho .* cos(theta);

        case 'conic_equal_area'
            lat1 = deg2rad(center_lat - 10);
            lat2 = deg2rad(center_lat + 10);
            n = 0.5 * (sin(lat1) + sin(lat2));
            C = cos(lat1).^2 + 2 * n * sin(lat1);
            rho = R * sqrt(C - 2 * n * sin(lat_rad)) / n;
            rho0 = R * sqrt(C - 2 * n * sin(center_lat_rad)) / n;
            theta = n * lon_adj;
            x = rho .* sin(theta);
            y = rho0 - rho .* cos(theta);

        case 'conic_equidistant'
            lat1 = deg2rad(center_lat - 10);
            lat2 = deg2rad(center_lat + 10);
            n = (sin(lat1) + sin(lat2)) / 2;
            G = cos(lat1)/n + lat1;
            rho = R * (G - lat_rad);
            theta = n * lon_adj;
            x = rho .* sin(theta);
            y = R * G - rho .* cos(theta);

        case 'oblique_conic'
            n = sin(stdlat_rad);
            lon_shifted = lon_rad - center_lon_rad;
            rho = R * cot(stdlat_rad) - lat_rad;
            theta = n * lon_shifted;
            x = rho .* sin(theta);
            y = -rho .* cos(theta);

        %% 圆柱投影
        case 'cylindrical_conformal'
            lat_safe = min(max(lat_rad, -pi/2 + eps), pi/2 - eps);
            x = R * lon_adj;
            y = R * log(tan(pi/4 + lat_safe/2));

        case 'cylindrical_equal_area'
            x = R * lon_adj;
            y = R * sin(lat_rad);

        case 'cylindrical_equidistant'
            x = R * lon_adj;
            y = R * lat_rad;

        case 'cylindrical_oblique'
            theta0 = center_lat_rad;
            lat_rot = asin(cos(theta0) .* sin(lat_rad) - ...
                           sin(theta0) .* cos(lat_rad) .* sin(lon_adj));
            lon_rot = atan2(cos(lat_rad) .* cos(lon_adj), ...
                            sin(theta0) .* sin(lat_rad) + ...
                            cos(theta0) .* cos(lat_rad) .* sin(lon_adj));
            x = R * lon_rot;
            y = R * lat_rot;

        case 'cylindrical_perspective'
            h = 2 * R;
            k = h ./ (h - cos(lat_rad));
            x = R * lon_adj .* k;
            y = R * lat_rad .* k;

        %% 特殊投影
        case 'gauss_kruger'
            k0 = 1;
            x = R * k0 * lon_adj;
            y = R * k0 * log(tan(pi/4 + lat_rad/2));

        case 'pseudo_azimuthal'
            x = R * lon_adj .* cos(lat_rad);
            y = R * lat_rad;

        case 'pseudo_cylindrical'
            x = R * lon_adj .* cos(lat_rad);
            y = R * lat_rad;

        case 'pseudo_conic'
            center_lat = mean(lat(:));  % 自动选取中心纬线
                phi_c = deg2rad(center_lat);  % 中心纬线弧度
            
                lat_rad = deg2rad(lat);
                lon_rad = deg2rad(lon);
                lon_adj = lon_rad - deg2rad(mean(lon(:)));  % 中央经线居中
            
                % 投影公式：使用 cos(center_lat) 缩放经度，纬度线性投影
                k = cos(phi_c);
                x = R * lon_adj * k;
                y = R * lat_rad;

        otherwise
            error('Unsupported projection type: %s', type);
    end
end
