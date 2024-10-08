t = [0];
m_sin = sin(t);
m_cos = cos(t);

% 绘制正弦曲线，设置颜色为绿色
p_sin = plot(t, m_sin, 'g', 'MarkerSize', 5);  % 正弦曲线
hold on;

% 绘制余弦曲线，设置颜色为蓝色
p_cos = plot(t, m_cos, 'b', 'MarkerSize', 5);  % 余弦曲线

% 设置初始坐标轴范围和背景
x = -1.5 * pi;
axis([x x + 2 * pi -1.5 1.5]);
grid on;

% 设置背景颜色为黑色，网格线为白色
set(gca, 'Color', 'k');  % 设置背景颜色为黑色
set(gca, 'GridColor', 'w');  % 设置网格线为白色

% 动态更新两条曲线的数据
for i = 1:1000
    % 更新时间和正弦、余弦数据
    t = [t 0.1 * i];  
    m_sin = [m_sin sin(0.1 * i)];
    m_cos = [m_cos cos(0.1 * i)];
    
    % 更新正弦曲线的数据
    set(p_sin, 'XData', t, 'YData', m_sin);
    
    % 更新余弦曲线的数据
    set(p_cos, 'XData', t, 'YData', m_cos);
    
    % 强制刷新图像
    drawnow;
    
    % 更新 X 轴范围，实现滚动效果
    x = x + 0.1;    
    axis([x x + 2 * pi -1.5 1.5]);
    
    % 暂停以控制动画速度
    pause(0.01);
end
