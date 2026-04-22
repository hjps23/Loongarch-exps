module div_unsigned (
  input wire clk,
  input wire reset,
  input wire [31:0] src1,
  input wire [31:0] src2,
  input wire div_en,
  output reg div_valid,
  output wire [31:0] div_res,
  output wire [31:0] div_remainder
);
  parameter IDLE = 2'd0;
  parameter CAL = 2'd1;
  reg [1:0] state;
  reg [4:0] cnt; // 32次迭代计数
  reg [31:0] dividend, divisor; // 被除数，除数
  reg [31:0] quotient, remainder; // 商，余数

  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      div_valid <= 1'b0;
      cnt <= 5'd0;
      dividend <= 32'd0;
      divisor <= 32'd0;
      quotient <= 32'd0;
      remainder <= 32'd0;
    end else begin
      case (state)
        IDLE: begin
          div_valid <= 1'b0;
          if (div_en) begin
            if (src2 == 32'd0) begin // 除数为零
              state <= IDLE;
              div_valid <= 1'b1;
              quotient <= 32'd0;
              remainder <= 32'd0;
            end else begin
              dividend <= src1;
              divisor <= src2;
              quotient <= 32'd0;
              remainder <= 32'd0;
              cnt <= 5'd31; // 32次迭代
              state <= CAL;
            end
          end
        end
        CAL: begin
          // {remainder, dividend}整体左移，dividend的MSB移入remainder的LSB
          dividend <= {dividend[30:0], 1'b0};
          quotient <= {quotient[30:0], 1'b0};
          if ({remainder[30:0], dividend[31]} >= divisor) begin
            remainder <= {remainder[30:0], dividend[31]} - divisor;
            quotient[0] <= 1'b1;
          end else begin
            remainder <= {remainder[30:0], dividend[31]};
          end
          if (cnt == 5'd0) begin
            state <= IDLE;
            div_valid <= 1'b1;
          end else begin
            cnt <= cnt - 1'b1;
          end
        end
      endcase
    end
  end

  assign div_res = quotient; // 输出商
  assign div_remainder = remainder; // 输出余数
endmodule
