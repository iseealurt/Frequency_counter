module keyboard_input(
input wire sys_clk,
input wire sys_rst,
input wire [3:0] column,

output reg [3:0] row,
output reg [15:0] keyboard_output
);
parameter scan_period = 16'd49999;
// 扫描周期5ms，前4ms记录键盘数据，第5ms输出数据，格式为
//第一行键盘输入情况 a1 a2 a3 a4
//第二行键盘输入情况 b1 b2 b3 b4
//第三行键盘输入情况 c1 c2 c3 c4
//第四行键盘输入情况 d1 d2 d3 d4
reg [15:0] scan_cnt; // 1ms计数器
reg [2:0] row_cnt; //行扫描计数器

reg [3:0] key_reg; //缓存键盘输入数据，每扫描一行更新一次
reg [15:0] data_temp;

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		scan_cnt <= 16'd0;
	else
		scan_cnt <= scan_cnt == scan_period ? 16'd0 : scan_cnt + 16'd1;
end

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		row_cnt <= 3'd0;
	else
        if(scan_cnt == scan_period) row_cnt <= row_cnt == 3'd4 ? 3'd0 : row_cnt + 3'd1;
end

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) begin 
		row <= 4'b1111;
	end
	else begin
		if (scan_cnt == 16'd0) begin //最先打开采样闸门
			case(row_cnt)
				3'd0: row <= 4'bzzz0;
				3'd1: row <= 4'bzz0z;
				3'd2: row <= 4'bz0zz;
				3'd3: row <= 4'b0zzz;
				default: row <= 4'b1111;
			endcase
		end
	end
end

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		key_reg <= 4'd0;
	else 
        if (scan_cnt == 16'd24999 && row_cnt != 3'd4) key_reg <= ~ column; //中间时刻采样
end

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) begin
		data_temp <= 16'd0;
		keyboard_output <= 16'd0;
	end
	else begin
        if (scan_cnt == scan_period && row_cnt == 3'd4) begin keyboard_output<= data_temp; end 
		else if (scan_cnt == scan_period ) begin //末端时刻输出
            if (row_cnt != 3'd4) begin 
				case (row_cnt)
					3'd0: begin data_temp[3:0] <= key_reg; end
					3'd1: begin data_temp[7:4] <= key_reg; end
					3'd2: begin data_temp[11:8] <= key_reg; end
					3'd3: begin data_temp[15:12] <= key_reg; end
					3'd4: begin end
					default:begin end
				endcase
			end
		end
	end
end
    
endmodule 