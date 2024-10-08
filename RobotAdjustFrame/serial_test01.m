function receive_and_print_serial_data()
    % 关闭所有已打开的串口对象
    fclose(instrfind);
    delete(instrfind);

    % 串口参数配置
    port = 'COM5';  % 根据实际情况修改串口号
    baudRate = 115200;
    dataBits = 8;
    stopBits = 1;
    parity = 'none';

    % 打开串口
    s = serial(port, 'BaudRate', baudRate, 'DataBits', dataBits, 'StopBits', stopBits, 'Parity', parity);
    s.InputBufferSize = 4096;
    s.BytesAvailableFcnMode = 'byte';
    s.BytesAvailableFcnCount = 1;  % 每次收到一个字节触发一次中断
    s.ReadAsyncMode = 'continuous';

    try
        fopen(s);  % 打开串口
    catch err
        fprintf('Error opening serial port: %s\n', err.message);
        return;
    end

    % 数据帧配置
    FRAME_HEAD_0 = uint8(0xFC);
    FRAME_HEAD_1 = uint8(0xFB);
    FRAME_END_0 = uint8(0xFD);
    FRAME_END_1 = uint8(0xFE);
    MAX_DATA_LENGTH = 16;

    % 状态机状态定义
    WAITING_FOR_HEADER_0 = 0;
    WAITING_FOR_HEADER_1 = 1;
    WAITING_FOR_ID = 2;
    WAITING_FOR_LENGTH = 3;
    WAITING_FOR_DATA = 4;
    WAITING_FOR_CRC_0 = 5;
    WAITING_FOR_CRC_1 = 6;
    WAITING_FOR_END_0 = 7;
    WAITING_FOR_END_1 = 8;

    % 初始化状态
    rx_state = WAITING_FOR_HEADER_0;
    rx_index = 0;
    rx_temp_data = zeros(1, MAX_DATA_LENGTH * 4, 'uint8');
    rx_frame = struct('data_length', 0, 'frame_head', zeros(1, 2, 'uint8'), ...
                      'frame_id', 0, 'crc_calculated', 0, ...
                      'data', zeros(1, MAX_DATA_LENGTH, 'single'), ...
                      'crc_code', 0, 'frame_end', zeros(1, 2, 'uint8'));

    % 实时接收和处理数据
    while true
        if s.BytesAvailable > 0
            byte = fread(s, 1, 'uint8');
            [rx_state, rx_index, rx_frame, rx_temp_data] = handle_serial_data(byte, rx_state, rx_index, rx_frame, rx_temp_data, ...
                                                                             FRAME_HEAD_0, FRAME_HEAD_1, FRAME_END_0, FRAME_END_1, ...
                                                                             WAITING_FOR_HEADER_0, WAITING_FOR_HEADER_1, WAITING_FOR_ID, ...
                                                                             WAITING_FOR_LENGTH, WAITING_FOR_DATA, WAITING_FOR_CRC_0, ...
                                                                             WAITING_FOR_CRC_1, WAITING_FOR_END_0, WAITING_FOR_END_1);
            if rx_state == WAITING_FOR_HEADER_0 && rx_index == 0
                if rx_frame.crc_code ~= rx_frame.crc_calculated
                    % CRC check failed, print debug information
                    fprintf('Error: CRC check failed. Received CRC: %d, Calculated CRC: %d\n', rx_frame.crc_code, rx_frame.crc_calculated);
                    fprintf('Received data: %s\n', mat2str(rx_temp_data));
                else
                    % 打印数据帧ID和数据
                    fprintf('Frame ID: %d\n', rx_frame.frame_id);
                    fprintf('Data: %s\n', mat2str(rx_frame.data));
                end
            end
        end
        pause(0.01); % 避免CPU占用过高
    end
end

function [rx_state, rx_index, rx_frame, rx_temp_data] = handle_serial_data(byte, rx_state, rx_index, rx_frame, rx_temp_data, ...
                                                                           FRAME_HEAD_0, FRAME_HEAD_1, FRAME_END_0, FRAME_END_1, ...
                                                                           WAITING_FOR_HEADER_0, WAITING_FOR_HEADER_1, WAITING_FOR_ID, ...
                                                                           WAITING_FOR_LENGTH, WAITING_FOR_DATA, WAITING_FOR_CRC_0, ...
                                                                           WAITING_FOR_CRC_1, WAITING_FOR_END_0, WAITING_FOR_END_1)
    switch rx_state
        case WAITING_FOR_HEADER_0
            if byte == FRAME_HEAD_0
                rx_frame.frame_head(1) = byte;
                rx_state = WAITING_FOR_HEADER_1;
            end

        case WAITING_FOR_HEADER_1
            if byte == FRAME_HEAD_1
                rx_frame.frame_head(2) = byte;
                rx_state = WAITING_FOR_ID;
            else
                rx_state = WAITING_FOR_HEADER_0;
            end

        case WAITING_FOR_ID
            rx_frame.frame_id = byte;
            rx_state = WAITING_FOR_LENGTH;

        case WAITING_FOR_LENGTH
            rx_frame.data_length = byte;
            rx_index = 0;
            rx_state = WAITING_FOR_DATA;

        case WAITING_FOR_DATA
            rx_temp_data(rx_index + 1) = byte;
            rx_index = rx_index + 1;
            if rx_index >= rx_frame.data_length * 4
                rx_state = WAITING_FOR_CRC_0;
            end

        case WAITING_FOR_CRC_0
            rx_frame.crc_code = byte;
            rx_state = WAITING_FOR_CRC_1;

        case WAITING_FOR_CRC_1
            rx_frame.crc_code = bitor(rx_frame.crc_code, bitshift(byte, 8));
            rx_state = WAITING_FOR_END_0;

        case WAITING_FOR_END_0
            if byte == FRAME_END_0
                rx_frame.frame_end(1) = byte;
                rx_state = WAITING_FOR_END_1;
            else
                rx_state = WAITING_FOR_HEADER_0;
            end

        case WAITING_FOR_END_1
            if byte == FRAME_END_1
                rx_frame.frame_end(2) = byte;
                rx_frame.crc_calculated = crc16(rx_temp_data, rx_frame.data_length * 4);
                if rx_frame.crc_code == rx_frame.crc_calculated
                    % CRC 校验通过，处理数据
                    rx_frame.data = typecast(uint8(rx_temp_data(1:rx_frame.data_length * 4)), 'single');
                end
                rx_state = WAITING_FOR_HEADER_0;
            else
                rx_state = WAITING_FOR_HEADER_0;
            end
    end
end

function crc = crc16(data, len)
    polynomial = uint16(hex2dec('1021'));
    crc = uint16(0xFFFF);

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

    % 如果输入的数据全为0，将crc校验结果也设置为0
    if all(data == 0)
        crc = uint16(0);
    end
end


