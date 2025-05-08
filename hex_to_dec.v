module hex_to_dec(
    input [23:0] data_input,   // 输入：24位二进制 高16位为整数部分，低8位为小数部分
    output [23:0] data_output  // 输出：24位BCD（6位十进制），前5个BCD码输出整数部分，后1个BCD码输出小数部分
);

// 寄存器声明
reg [3:0] bcd_integer [4:0];  // 5位整数BCD码
reg [3:0] bcd_fraction;       // 1位小数BCD码
reg [15:0] integer_part;      // 整数部分
reg [7:0] fraction_part;      // 小数部分

// 中间变量
integer i, j;

// 主转换逻辑
always @(*) begin
    // 分离整数和小数部分
    integer_part = data_input[23:8];
    fraction_part = data_input[7:0];
    
    // 整数部分转换（双循环算法）
    for (i = 0; i < 5; i = i + 1) begin
        bcd_integer[i] = 4'b0;
    end
    
    for (i = 15; i >= 0; i = i - 1) begin
        // 检查并调整BCD码
        for (j = 0; j < 5; j = j + 1) begin
            if (bcd_integer[j] >= 4'b0101) begin
                bcd_integer[j] = bcd_integer[j] + 4'b0011;
            end
        end
        
        // 左移一位
        for (j = 4; j > 0; j = j - 1) begin
            bcd_integer[j] = {bcd_integer[j][2:0], bcd_integer[j-1][3]};
        end
        bcd_integer[0] = {bcd_integer[0][2:0], integer_part[i]};
    end
    
    // 小数部分转换（简单近似）
    bcd_fraction = (fraction_part * 10) >> 8;  // 将小数部分乘以10然后取高4位
end

// 组合输出
assign data_output = {
    bcd_integer[4], 
    bcd_integer[3], 
    bcd_integer[2], 
    bcd_integer[1], 
    bcd_integer[0], 
    bcd_fraction
};

endmodule
