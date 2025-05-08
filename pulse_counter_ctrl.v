module pulse_counter_ctrl (
	input wire sys_clk,
	input wire sys_rst,
	input wire cnt_OE,
	input wire counter_data_en,
	input wire [3:0] test_interval,
	output reg OE
);
	//cnt_OE 变为高电平时开始测量频率，OE变为高电平直到counter_data_en 变为高电平后变低，当经过
	//test_interval后重新开始测量，直到测量周期结束
	parameter cnt_value_100ms = 49_999_99;
	
	reg cnt_100ms_flag;
	reg [23:0] cnt_100ms;
	reg [3:0] cycle_cnt;
	reg [3:0] interval_cnt;

	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin cnt_100ms <= 24'd0;end
		else begin 
			if (cnt_100ms_flag) begin 
				cnt_100ms <= cnt_100ms == cnt_value_100ms ? 24'd0 : cnt_100ms + 24'd1; 
			end
			else begin 
				cnt_100ms <= 24'd0; 
			end
		end
	end 
	// 100ms计数器
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin interval_cnt <= 4'd0; end
		else begin 
			if (cnt_100ms_flag) begin 
				if (cnt_100ms == cnt_value_100ms) begin
					interval_cnt <= interval_cnt == test_interval ? 4'd0 : interval_cnt + 4'd1;
				end
				else begin interval_cnt <= interval_cnt;end
			end
			else begin interval_cnt<= 4'd0; end
		end
	end
	// 测量间隔计时器
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin OE <= 1'b0;cnt_100ms_flag <= 1'b0;end
		else begin
			if (cnt_OE) begin 
				if (!counter_data_en && !cnt_100ms_flag) begin OE <= 1'b1; cnt_100ms_flag <= 1'b0; end 
				else if (counter_data_en && !cnt_100ms_flag )begin OE <= 1'b0; cnt_100ms_flag <= 1'b1; end
				else if (cnt_100ms_flag) begin 
					OE <= 1'b0; 
                    if (interval_cnt == test_interval && cnt_100ms == cnt_value_100ms) begin 
                        cnt_100ms_flag <= 1'b0;
                    end
				end
			end
			else begin OE <= 1'b0; cnt_100ms_flag<= 1'b0; end
		end
	end 
	// 频率计模块控制
endmodule