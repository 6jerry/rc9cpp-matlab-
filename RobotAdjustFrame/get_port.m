% 获取所有可用的串口号
function ports_info = get_port()
   ports = serialportlist;
   for i = 1:length(ports)
    %portInfo = instrhwinfo('serial', ports{i});
    % 指定的端口号
   

% 构建 PowerShell 命令，动态插入 port 变量
        command = ['powershell "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match ''', char(ports(i)), ''' } | Select-Object -ExpandProperty Name"'];
        %matlab中的两种字符串类型：字符向量（字符数组）和字符向量，system需要的是字符向量
    % 运行 PowerShell 命令并获取输出
        [status, cmdout] = system(command);
        %disp(cmdout);
        serial_devices(i)=string(cmdout);
   
    %portInfo(i) = extractBetween(serial_devices(i).name, "(", ")");
   end
   %disp(serial_devices);
   ports_info=serial_devices;
end







