module key_filter(

input wire sys_clk,
input wire sys_rst,
input wire key_input,

output reg key_reg

);

reg [12:0] cnt_5000;

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		cnt_5000 <= 13'd0;
	else 
		cnt_5000 <= cnt_5000 == 13'd4999 ? 13'd0 : cnt_5000 + 13'd1;
end


always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		key_reg <= 1'bz;
	else 
		if (cnt_5000 == 13'd4999)
			key_reg <= key_input;
end 

endmodule
