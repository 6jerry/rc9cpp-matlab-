t=[0]
m=[0];
p = plot(t,m,'g','MarkerSize',5);%LineSpec 应该作为第三个位置的字符串输入

x=-1.5*pi;
axis([x x+2*pi -1.5 1.5]);
grid on;
% 设置背景颜色为黑色
set(gca, 'Color', 'k');  % 'k' 表示黑色
set(gca, 'GridColor', 'w');  % 设置网格线颜色为白色
for i=1:1000
    t=[t 0.1*i];  
    m=[m sin(0.1*i)]; 
    set(p,'XData',t,'YData',m)   
    drawnow
    x=x+0.1;    
    axis([x x+2*pi -1.5 1.5]);
    %pause(0.01);
end
