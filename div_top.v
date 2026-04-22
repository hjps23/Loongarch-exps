module div_top (
  input wire clk,
  input wire reset,
  input wire [31:0] src1,    // 被除数
  input wire [31:0] src2,    // 除数
  input wire div_en,        // 除法使能
  input wire div_is_signed, // 是否为有符号除法
  output wire div_valid,   // 结果有效
  output wire [31:0] div_res, // 结果（商）
  output wire [31:0] div_remainder, // 结果（余数）
  output wire busy         // 除法是否在进行中
);
  // 实例化有符号和无符号除法模块（增加余数输出）
  wire [31:0] div_signed_res;
  wire div_signed_valid;
  wire [31:0] div_signed_remainder;
  wire [31:0] div_unsigned_res;
  wire div_unsigned_valid;
  wire [31:0] div_unsigned_remainder;

  div_signed u_div_signed (
    .clk(clk),
    .reset(reset),
    .src1(src1),
    .src2(src2),
    .div_en(div_en),
    .div_valid(div_signed_valid),
    .div_res(div_signed_res),
    .div_remainder(div_signed_remainder)
  );

  div_unsigned u_div_unsigned (
    .clk(clk),
    .reset(reset),
    .src1(src1),
    .src2(src2),
    .div_en(div_en),
    .div_valid(div_unsigned_valid),
    .div_res(div_unsigned_res),
    .div_remainder(div_unsigned_remainder)
  );

  // 选择商和余数（根据符号）
  assign div_res = div_is_signed ? div_signed_res : div_unsigned_res;
  assign div_remainder = div_is_signed ? div_signed_remainder : div_unsigned_remainder;
  assign div_valid = div_is_signed ? div_signed_valid : div_unsigned_valid;

  // 生成busy信号（除法执行期间为高）
  reg busy_r;
  always @(posedge clk) begin
    if (reset) begin
      busy_r <= 1'b0;
    end else begin
      if (div_en && !div_valid) begin
        busy_r <= 1'b1;
      end else if (div_valid) begin
        busy_r <= 1'b0;
      end
    end
  end
  assign busy = busy_r;
endmodule
