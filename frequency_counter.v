module frequency_counter (
	input wire sys_clk,
	input wire sys_rst,
	input wire key_1,
	input wire to_be_measured_clk,
	input wire [3:0] keyboard_column,
	input wire [7:0] eight_bit_switch_input,
	output wire [3:0] keyboard_row,
	output wire [5:0] led_sel1,
	output wire [7:0] led_seg1,
	output wire [5:0] led_sel2,
	output wire test_clk_output,
	output wire [7:0] led_seg2,
	
	output wire led_OE,
	output wire led_data_en
);
	wire freq_data_en;
	wire [23:0] freq_out;
	wire pll_locked;
	wire [23:0] freq_dec;
	wire [7:0] switch_wire;
	wire [15:0] keyboard_output;
	wire key1_out;
	wire OE;
	
	reg [23:0] freq_out_temp;
	
	assign led_OE = OE;
	assign led_data_en = freq_data_en;
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if(!sys_rst) begin freq_out_temp <= 24'd0; end
		else begin
			if (freq_data_en == 1'b1) freq_out_temp <= freq_out;
		end
	end
 	
	keyboard_input keyboard_input_inst(
		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.column(keyboard_column),
		.row(keyboard_row),
		.keyboard_output(keyboard_output)
	);

	led_display led_display_inst1(
		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.data_input({switch_wire,keyboard_output}),
		.dot_sel(6'd0),
		.sel(led_sel1),
		.seg(led_seg1)
	);
	
	led_display led_display_inst2(
		.sys_clk(sys_clk), 
		.sys_rst(sys_rst),
		.data_input(freq_dec),
		.dot_sel(6'b000_010),
		.sel(led_sel2),
		.seg(led_seg2)
	);
	
	eight_bit_switch eight_bit_switch_inst(

		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.switch_input(eight_bit_switch_input),
		.switch_output(switch_wire)
	);
	
	stand_frequency_generator stand_frequency_generator_inst(
		.areset(~sys_rst),
		.inclk0(sys_clk),
		.c0(test_clk_output),
		.locked(pll_locked)
	);
	
	pulse_counter pulse_counter_inst(
		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.to_be_measured_clk(to_be_measured_clk),
		.OE(OE),
		.gate_time(switch_wire),
		.frequency(freq_out),
		.data_en(freq_data_en)
	);
	
	key_filter key_filter_inst(
		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.key_input(key_1),
		.key_reg(key1_out)
	);
	
	hex_to_dec hex_to_dec_inst(
		.data_input(freq_out_temp),  
		.data_output(freq_dec)
	);
	
	pulse_counter_ctrl pulse_counter_ctrl_inst(
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .cnt_OE(~key1_out),
        .counter_data_en(freq_data_en),
        .test_interval(4'd3),
        .OE(OE)
    );
endmodule