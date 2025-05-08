module eight_bit_switch (

	input wire sys_clk,
	input wire sys_rst,
	input wire [7:0] switch_input,

	output reg [7:0] switch_output
	
);
	parameter scan_period = 16'd49999; // 扫描周期1ms
	
	reg [15:0] scan_period_cnt;
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) 
			scan_period_cnt <= 16'd0;
		else 
			scan_period_cnt <= scan_period_cnt == scan_period ? 16'd0 : scan_period_cnt + 16'd1;
	end
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst)
			switch_output <= 16'd0;
		else 
			if (scan_period_cnt == 16'd24999) switch_output <= switch_input;
	end
	
endmodule