% 设置串口参数
baudRate = 115200;
serialPort = "COM5"; % 根据实际情况修改串口号

% 初始化串口对象
try
    s = serialport(serialPort, baudRate);
    disp('串口打开成功');
catch
    error('无法打开串口');
end

% 配置串口缓冲区
configureTerminator(s, "LF");
flush(s); % 清空缓冲区

% 定义数据帧格式
frame_head_0 = 0xFC;
frame_head_1 = 0xFB;
frame_end_0 = 0xFD;
frame_end_1 = 0xFE;
max_data_length = 16;

% 初始化数据存储
data = zeros(1, max_data_length * 4);
data_length = 0;

% 状态机状态定义
state = 'WAITING_FOR_HEADER_0';

while true
    if s.NumBytesAvailable > 0
        byte = read(s, 1, 'uint8');
        disp(['Received byte: ', num2str(byte), ' State: ', state]);
        switch state
            case 'WAITING_FOR_HEADER_0'
                if byte == frame_head_0
                    state = 'WAITING_FOR_HEADER_1';
                end
            case 'WAITING_FOR_HEADER_1'
                if byte == frame_head_1
                    state = 'WAITING_FOR_ID';
                else
                    state = 'WAITING_FOR_HEADER_0';
                end
            case 'WAITING_FOR_ID'
                frame_id = byte;
                state = 'WAITING_FOR_LENGTH';
            case 'WAITING_FOR_LENGTH'
                data_length = byte;
                if data_length > max_data_length
                    disp('错误: 数据长度超过最大限制');
                    state = 'WAITING_FOR_HEADER_0';
                else
                    data_index = 1;
                    state = 'WAITING_FOR_DATA';
                end
            case 'WAITING_FOR_DATA'
                data(data_index) = byte;
                data_index = data_index + 1;
                if data_index > data_length * 4
                    state = 'WAITING_FOR_CRC_0';
                end
            case 'WAITING_FOR_CRC_0'
                crc_0 = byte;
                state = 'WAITING_FOR_CRC_1';
            case 'WAITING_FOR_CRC_1'
                crc_1 = byte;
                state = 'WAITING_FOR_END_0';
            case 'WAITING_FOR_END_0'
                if byte == frame_end_0
                    state = 'WAITING_FOR_END_1';
                else
                    disp('错误: 帧尾校验失败');
                    state = 'WAITING_FOR_HEADER_0';
                end
            case 'WAITING_FOR_END_1'
                if byte == frame_end_1
                    % 计算CRC并验证
                    received_crc = bitshift(crc_1, 8) + crc_0;
                    calculated_crc = crc16(data, data_length * 4);
                    disp(['Received CRC: ', num2str(received_crc)]);
                    disp(['Calculated CRC: ', num2str(calculated_crc)]);
                    if received_crc == calculated_crc
                        % 解析数据
                        data_floats = typecast(uint8(data(1:data_length * 4)), 'single');
                        disp(data_floats); % 显示接收到的数据
                        % 在此调用绘图函数
                        plot_data(data_floats);
                    else
                        disp('错误: CRC校验失败');
                    end
                else
                    disp('错误: 帧尾校验失败');
                end
                state = 'WAITING_FOR_HEADER_0';
        end
    end
end

function plot_data(data_floats)
    persistent h;
    if isempty(h)
        figure;
        h = plot(data_floats);
        ylim([min(data_floats)-1, max(data_floats)+1]);
        title('Real-time Data Plot');
        xlabel('Data Index');
        ylabel('Data Value');
        grid on;
    else
        set(h, 'YData', data_floats);
        drawnow;
    end
end

function crc = crc16(data, len)
    % 计算CRC16校验码
    crc = uint16(0xFFFF);
    polynomial = uint16(0x1021);
    for i = 1:len
        crc = bitxor(crc, bitshift(uint16(data(i)), 8));
        for j = 1:8
            if bitand(crc, uint16(0x8000))
                crc = bitxor(bitshift(crc, 1), polynomial);
            else
                crc = bitshift(crc, 1);
            end
        end
    end
end
