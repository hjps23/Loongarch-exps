`timescale 1ns / 1ps
`include"Bp_Define.vh"
module BP_PHT(
    input wire                         clk,
    input wire                         reset,
    // from is
    input wire [`PhtWbusWidth -1:0]    w_ibus,
    // now state
    input wire [`PhtAddrWidth -1:0]    raddr_i,
    output wire [`PhtStateWidth -1:0]  rdata_o
  );
  
      //wdata
     wire we_i;
     wire [`PhtAddrWidth -1:0]waddr_i;
     wire [`PhtStateWidth -1:0]wdata_i;
     wire re;
     wire [`PhtStateWidth -1:0]rdata;
     
     assign {we_i,waddr_i,wdata_i} =  w_ibus;
      
     assign re = we_i && (waddr_i==raddr_i) ? 1'b0:1'b1;
     assign rdata_o = !re ? wdata_i : rdata;
     pht_ram pht (
      .clka(clk),    // input wire clka
      
      //in
      .ena(1'b1),      // input wire ena
      .wea(we_i),      // input wire [0 : 0] wea
      .addra(waddr_i),  // input wire [9 : 0] addra
      .dina(wdata_i),    // input wire [1: 0] dina
      
      //out
      .clkb(clk),    // input wire clkb
      .enb(1'b1),      // input wire enb
      .addrb(raddr_i),  // input wire [9 : 0] addrb
      .doutb(rdata)  // output wire [1 : 0] doutb
    );
       
 
endmodule