module div_signed (
  input wire clk,
  input wire reset,
  input wire [31:0] src1,
  input wire [31:0] src2,
  input wire div_en,
  output reg div_valid,
  output reg [31:0] div_res,
  output reg [31:0] div_remainder
);
  wire [31:0] abs_src1, abs_src2; // 绝对值
  wire [31:0] unsigned_res;
  wire unsigned_valid;
  wire [31:0] unsigned_remainder;

  // 取绝对值（补码转原码）
  assign abs_src1 = (src1[31] == 1'b1) ? (~src1 + 1'b1) : src1;
  assign abs_src2 = (src2[31] == 1'b1) ? (~src2 + 1'b1) : src2;

  // 调用无符号除法模块（增加余数输出）
  div_unsigned u_div_unsigned (
    .clk(clk),
    .reset(reset),
    .src1(abs_src1),
    .src2(abs_src2),
    .div_en(div_en),
    .div_valid(unsigned_valid),
    .div_res(unsigned_res),
    .div_remainder(unsigned_remainder)
  );

  // 调整符号（商和余数）
  always @(posedge clk) begin
    if (reset) begin
      div_valid <= 1'b0;
    end else if (unsigned_valid) begin
      div_valid <= 1'b1;
      // 商的符号：被除数和除数符号不同则为负
      if (src1[31] ^ src2[31]) begin
        div_res <= (~unsigned_res + 1'b1);
      end else begin
        div_res <= unsigned_res;
      end
      
      // 余数的符号：始终与被除数一致
      if (src1[31] == 1'b1) begin // 被除数为负，余数需为负
        div_remainder <= (~unsigned_remainder + 1'b1);
      end else begin // 被除数为正，余数直接使用无符号结果
        div_remainder <= unsigned_remainder;
      end
    end else begin
      div_valid <= 1'b0;
    end
  end
endmodule
