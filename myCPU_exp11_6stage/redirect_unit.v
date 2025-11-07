`timescale 1ns / 1ps
module redirect_unit(
    // ID阶段信息
    input  wire [4:0]  rj_in,
    input  wire [4:0]  rkd_in,
    // EX阶段信息
    input  wire        ex_gr_we,
    input  wire [4:0]  ex_dest,
    
    // MEM阶段信息  
    input  wire        mem_gr_we,
    input  wire [4:0]  mem_dest,
    
    // WB阶段信息
    input  wire        wb_gr_we,
    input  wire [4:0]  wb_dest,
    
    // 重定向控制信号
    output reg  [1:0]  rj_redirect,
    output reg  [1:0]  rkd_redirect
);


// rj重定向逻辑
always @(*) begin
    if (ex_gr_we && ex_dest != 5'b0 && ex_dest == rj_in) begin
        rj_redirect = 2'b01;  // 从EX阶段重定向
    end else if ((mem_gr_we && mem_dest != 5'b0 && mem_dest == rj_in)) begin
        rj_redirect = 2'b10;  // 从MEM阶段重定向
    end else if (wb_gr_we && wb_dest != 5'b0 && wb_dest == rj_in) begin
        rj_redirect = 2'b11;  // 从WB阶段重定向
    end else begin
        rj_redirect = 2'b00;  // 无重定向
    end
end

// rk/rd重定向逻辑
always @(*) begin
    if (ex_gr_we && ex_dest != 5'b0 && ex_dest == rkd_in) begin
        rkd_redirect = 2'b01;  // 从EX阶段重定向
    end else if ((mem_gr_we && mem_dest != 5'b0 && mem_dest == rkd_in)) begin
        rkd_redirect = 2'b10;  // 从MEM阶段重定向
    end else if (wb_gr_we && wb_dest != 5'b0 && wb_dest == rkd_in) begin
        rkd_redirect = 2'b11;  // 从WB阶段重定向
    end else begin
        rkd_redirect = 2'b00;  // 无重定向
    end
end

endmodule