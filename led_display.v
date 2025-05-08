module led_display(

input wire sys_clk,
input wire sys_rst, // 异步归零
input wire [23:0] data_input,
input wire [5:0] dot_sel,
output reg [5:0] sel,
output reg [7:0] seg

);
parameter    SEG_0 = 8'b1100_0000,    SEG_0_DP = 8'b0100_0000,  // 0 → 0. (DP点亮)
             SEG_1 = 8'b1111_1001,    SEG_1_DP = 8'b0111_1001,  // 1 → 1.
             SEG_2 = 8'b1010_0100,    SEG_2_DP = 8'b0010_0100,  // 2 → 2.
             SEG_3 = 8'b1011_0000,    SEG_3_DP = 8'b0011_0000,  // 3 → 3.
             SEG_4 = 8'b1001_1001,    SEG_4_DP = 8'b0001_1001,  // 4 → 4.
             SEG_5 = 8'b1001_0010,    SEG_5_DP = 8'b0001_0010,  // 5 → 5.
             SEG_6 = 8'b1000_0010,    SEG_6_DP = 8'b0000_0010,  // 6 → 6.
             SEG_7 = 8'b1111_1000,    SEG_7_DP = 8'b0111_1000,  // 7 → 7.
             SEG_8 = 8'b1000_0000,    SEG_8_DP = 8'b0000_0000,  // 8 → 8.
             SEG_9 = 8'b1001_0000,    SEG_9_DP = 8'b0001_0000,  // 9 → 9.
             SEG_A = 8'b1000_1000,    SEG_A_DP = 8'b0000_1000,  // A → A.
             SEG_B = 8'b1000_0011,    SEG_B_DP = 8'b0000_0011,  // B → B.
             SEG_C = 8'b1100_0110,    SEG_C_DP = 8'b0100_0110,  // C → C.
             SEG_D = 8'b1010_0001,    SEG_D_DP = 8'b0010_0001,  // D → D.
             SEG_E = 8'b1000_0110,    SEG_E_DP = 8'b0000_0110,  // E → E.
             SEG_F = 8'b1000_1110,    SEG_F_DP = 8'b0000_1110;  // F → F.

//数码管段选转换参数
reg [9:0] cnt_1000;
// 1000分频

reg [2:0] sel_cnt;
// 位选计数器

reg [23:0] data_temp;
// 数据缓存

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst)
		data_temp <= 24'd0;
	else 
		data_temp <= data_input;
end
// 同步数据缓存

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst)
		cnt_1000 <= 10'd0;
	else 
		cnt_1000 <= cnt_1000 == 10'd999 ? 10'd0 : cnt_1000 + 10'd1;
end

// 1000分频

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) 
		sel_cnt <= 3'd0;
	else 
		if(cnt_1000 == 10'd999) 
			sel_cnt <= sel_cnt == 3'd5 ? 3'd0 : sel_cnt + 3'd1;
end

always@(posedge sys_clk or negedge sys_rst) begin
	if (!sys_rst) begin
		seg <= SEG_0;
    	sel <= 6'b11_1111;
	end
	else begin
        if (cnt_1000 == 10'd999) begin
			case (sel_cnt)
				3'd0: sel <= 6'b011_111;
				3'd1: sel <= 6'b101_111;
				3'd2: sel <= 6'b110_111;
				3'd3: sel <= 6'b111_011;
				3'd4: sel <= 6'b111_101;
				3'd5: sel <= 6'b111_110;
				default: sel<= 6'b111_111;
			endcase
			case (data_temp[(sel_cnt * 4) +: 4])
				4'b0000: seg <= !dot_sel[sel_cnt] ? SEG_0 : SEG_0_DP;
				4'b0001: seg <= !dot_sel[sel_cnt] ? SEG_1 : SEG_1_DP;
				4'b0010: seg <= !dot_sel[sel_cnt] ? SEG_2 : SEG_2_DP;
				4'b0011: seg <= !dot_sel[sel_cnt] ? SEG_3 : SEG_3_DP;
				4'b0100: seg <= !dot_sel[sel_cnt] ? SEG_4 : SEG_4_DP;
				4'b0101: seg <= !dot_sel[sel_cnt] ? SEG_5 : SEG_5_DP;
				4'b0110: seg <= !dot_sel[sel_cnt] ? SEG_6 : SEG_6_DP;
				4'b0111: seg <= !dot_sel[sel_cnt] ? SEG_7 : SEG_7_DP;
				4'b1000: seg <= !dot_sel[sel_cnt] ? SEG_8 : SEG_8_DP;
				4'b1001: seg <= !dot_sel[sel_cnt] ? SEG_9 : SEG_9_DP;
				4'b1010: seg <= !dot_sel[sel_cnt] ? SEG_A : SEG_A_DP;
				4'b1011: seg <= !dot_sel[sel_cnt] ? SEG_B : SEG_B_DP;
				4'b1100: seg <= !dot_sel[sel_cnt] ? SEG_C : SEG_C_DP;
				4'b1101: seg <= !dot_sel[sel_cnt] ? SEG_D : SEG_D_DP;
				4'b1110: seg <= !dot_sel[sel_cnt] ? SEG_E : SEG_E_DP;
				4'b1111: seg <= !dot_sel[sel_cnt] ? SEG_F : SEG_F_DP;
				default: seg <= SEG_0;
			endcase
        end
	end
end
    
endmodule