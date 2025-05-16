//模块功能：切换纯手动/半自动/全自动测量模式
//纯手动模式：不接收来自fifo的指令，也不进行脉冲信号匹配，手动设置测量周期，测量周期内直接测量信号频率
//半自动模式：不接收来自fifo的指令，按下测试按键后进行脉冲信号匹配，脉冲周期内测量信号频率
//全自动测量模式：接收来自fifo的指令，进行脉冲信号匹配，脉冲周期内测量信号频率
module manual_automatic_switcher(
	input wire sys_clk,
	input wire sys_rst,
	input wire state_ctrl_key_posedge,  //模式切换输入 //finished
	input wire [7:0] automatic_data_in,//自动模式指令/数据输入
	input wire automatic_data_en, // 自动模式指令有效指示 
	input wire manual_OE_posedge, //手动模式测量指令
	input wire automatic_test_en, //自动模式测试使能
	input wire [7:0] manual_test_period_input,
	input wire [7:0] manual_test_interval_input,
	//测试间隔和周期设置
	output wire out_OE, // 测量指令
	output reg [7:0] test_interval_output
);
	parameter cnt_value_1s = 28'd49_999_999;
	parameter state_pure_manual = 2'd0;
	parameter state_semi_automatic  = 2'd1;
	parameter state_fully_automatic = 2'd2;
	
	parameter interval_inst = 8'h01; //设置间隔指令
	parameter period_inst = 8'h02; //设置测量周期指令
	
	wire test_OE;
	
	reg [3:0] test_interval_reg;
	reg [3:0] test_period_reg;
	reg [27:0] cnt_1s;
	reg [3:0] cnt_period;
	reg [1:0] state;
	reg cnt_flag;//计数标志，也充当测试使能信号
	reg semi_automatic_test_flag;
	
	assign out_OE = cnt_flag;
	
	//纯手动/半自动/全自动测量状态指示
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin state <= state_pure_manual; end
		else begin
			if (state_ctrl_key_posedge) begin state <= state == state_fully_automatic ? 2'd0 : state + 2'd1; end
			else begin state <= state; end
		end
	end
	//状态机跳变
	
	always@(*) begin
		if (state == state_pure_manual) begin test_OE = manual_posedge; end
		else if(state == state_semi_automatic) begin 
			test_OE = semi_automatic_test_flag ? automatic_test_en : manual_OE_posedge;
		 end
		else if(state == state_fully_automatic) begin test_OE = automatic_test_en; end
	end
	//测试使能切换
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) cnt_flag <= 1'b0;semi_automatic_test_flag <= 1'b0;
		else begin
			if (test_OE && cnt_flag == 1'b0) begin 
				if (state == state_pure_manual) begin cnt_flag <= 1'b1; end
				else if (state == state_fully_automatic) begin cnt_flag <= 1'b1; end
				else if (state == state_pure_manual) begin
					if (semi_automatic_test_flag==1'b0) begin semi_automatic_test_flag <= 1'b1;end
					else begin 
						cnt_flag <= 1'b1;
					end
				end
			end
			else begin
				if (state == state_pure_manual) begin 
					if (cnt_period == 4'd9 || cnt_period == test_period_reg && cnt_1s == cnt_value_1s) begin
						cnt_flag <= 1'b0;
					end
				end//测试周期器计数完成后结束计数
				else begin 
					if(test_OE && cnt_flag == 1'b1) begin cnt_flag <= 1'b0; end 
				end
			end
		end
	end
	//计数使能切换
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin cnt_1s <= 28'd0; end
		else begin 
			if (cnt_flag && state == state_pure_manual) begin cnt_1s <= cnt_1s == cnt_value_1s ? 28'd0 : cnt_1s + 28'd1;
			else begin cnt_1s <= 28'd0;end
		end
	end
	//1s计数器
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin cnt_period <= 4'd1; end
		else begin 
			if (cnt_flag && state == state_pure_manual) begin 
				if (cnt_1s == cnt_value_1s) begin 
					cnt_period <= (cnt_period == 4'd9 || cnt_period == test_period_reg) ? 4'd0 : cnt_period + 4'd1;
				end
			else begin cnt_period <= 4'd0;end
		end
	end
	//测试周期计数器
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) begin test_interval_reg <= 8'd10; test_period_reg <= 8'd1; end
		else begin
			if (state == state_pure_manual) begin 
				if (manual_test_interval_input >= 8'd9 && manual_test_interval_input <= 8'd19) begin 
					test_interval_reg <= manual_test_interval_input; 
				end
				else begin test_interval_reg <= 8'd10;end
				if (manual_test_period_input >= test_interval_reg/8'd10) begin 
					test_period_reg <= manual_test_period_input;
				end
				else begin test_period_reg <= test_interval_reg/8'd10; end
			end
			else begin
					//未完成
					//在半自动模式和自动模式下，如果FIFO核内有未读取的指令，则读取指令，判断指令内容
					//根据两种指令进行测量周期和测量间隔的缓存和输出
			end
		end
	end
	//测试周期和测试间隔寄存
endmodule
