module pulse_counter(
	input wire sys_clk,
	input wire sys_rst,
	input wire to_be_measured_clk,
	input wire OE,
	input wire [7:0] gate_time,
	
    output reg [23:0] frequency,
	output reg data_en
);
	parameter stand_frequency = 48'd50_000_000;
    parameter ms_value = 24'd49_999_9; // sys_clk = 50MHz，计10ms
	reg cnt_flag;
	reg [7:0] gate_time_temp;
	reg [23:0] cnt_ms;
	reg [7:0] gate_time_cnt;
	reg [47:0] stand_clk_cnt;
	reg [47:0] to_be_measured_clk_cnt;
	reg [1:0] to_be_measured_clk_reg;
	wire to_be_measured_clk_posedge;
	assign to_be_measured_clk_posedge = to_be_measured_clk_reg == 2'b01 ? 1'b1 : 1'b0;
	wire [47:0] scaled_value;  // 扩大后的位宽 = 32 + 48 + 8 = 88位（补足到96位简化计算）
	wire [47:0] div_result;
	// 1. 扩大被除数：先乘后左移8位（等价于整体左移8位保留小数）
	assign scaled_value = (stand_frequency * to_be_measured_clk_cnt) << 8;
	// 2. 执行除法运算
	assign div_result = scaled_value / stand_clk_cnt;
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if(!sys_rst) begin
			cnt_flag <= 1'b0;
			data_en <= 1'b0;
		end
		else begin
            if (OE) begin
				if (to_be_measured_clk_posedge && !cnt_flag) cnt_flag <= 1'b1; 
        		else if (cnt_flag) begin 
					if (gate_time_cnt == gate_time_temp && cnt_ms == ms_value) begin
						cnt_flag <= 1'b0;
						data_en <= 1'b1;
					end
					else if (data_en) begin
						cnt_flag <= 1'b0;
					end
				end
            end
        	else begin 
				cnt_flag <= 1'b0;
				data_en <= 1'b0;
			end
		end
	end
	// 计时标志设置
	
    always@(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) gate_time_temp <= 8'd0;
        else 
            if (to_be_measured_clk_posedge && !cnt_flag) gate_time_temp <= gate_time;
    end
    // 门时间缓存
                
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) 
			to_be_measured_clk_reg <= 2'b00;
		else
			if (OE) to_be_measured_clk_reg <= {to_be_measured_clk_reg,to_be_measured_clk};
			else to_be_measured_clk_reg <= 2'b00;
	end
	//被测试信号上升沿检测
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst)
			cnt_ms <= 24'd0;
		else 
			if (cnt_flag) cnt_ms <= cnt_ms == ms_value ? 24'd0 : cnt_ms + 24'd1;
			else cnt_ms <= 16'd0;
	end
	// 100ms计数
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) 
			gate_time_cnt <= 8'd0;
		else 
			if (cnt_flag && cnt_ms == ms_value) gate_time_cnt <= gate_time_cnt == gate_time ? 8'd0 : gate_time_cnt + 8'd1;			
	end
	// 计数门计时
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) 
			to_be_measured_clk_cnt <= 48'd0;
		else begin
            if (cnt_flag) begin
				if (to_be_measured_clk_posedge) to_be_measured_clk_cnt <= to_be_measured_clk_cnt + 48'd1;
            end
       		else begin to_be_measured_clk_cnt <= 48'd0; end
        end
	end
	// 被测试信号边沿计数
	
	always@(posedge sys_clk or negedge sys_rst) begin
		if (!sys_rst) 
			stand_clk_cnt <= 48'd0;
		else 
			if (cnt_flag) stand_clk_cnt <= stand_clk_cnt + 48'd1;
			else stand_clk_cnt <= 48'd0;
	end
	// 基准信号计数
    
    always@(posedge sys_clk or negedge sys_rst) begin
    if (!sys_rst) 
        frequency <= 48'd0;  // 扩展为32位（24位整数 + 8位小数）
    else 
        if (gate_time_cnt == gate_time_temp && cnt_ms == ms_value) begin
            // 核心操作：扩大被除数后除法，保留小数
            // 3. 取低32位结果（高24位整数 + 低8位小数）
            frequency <= div_result[23:0];
        end
	end
	// 结果计算
    
endmodule