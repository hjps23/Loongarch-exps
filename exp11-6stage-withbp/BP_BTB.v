`timescale 1ns / 1ps
`include"Bp_Define.vh"
module BP_BTB(
    input wire                          clk,
    input wire                          reset,
    // update
    input wire [`PcWidth -1:0]          pc_i,//current pc
    input wire [`BtbWbusWidth -1:0]     w_ibus,//update data
    // pre_result 
    output wire                         hit_o,//hit flag
    output wire [`PcWidth -1:0]         btb_branch_target_o //branch flag
    );
    
    // read interfaces
    wire [`BtbTagWidth -1:0]pc_tag_i;
    wire [`BtbAddrWidth -1:0]btb_raddr_i;
    wire [`BtbDataWidth -1:0]btb_rdata;
    
    // wdata
     wire we_i;      
     wire [`BtbAddrWidth -1:0]waddr_i;  
     wire [`BtbTagWidth -1:0]wtag_i;//22  
     wire [`PcWidth -1:0]w_predic_target_i;    
    
    
    wire valid;
    wire [`BtbTagWidth -1:0]btb_tag;
    wire re;

    
    assign {pc_tag_i,btb_raddr_i}=pc_i[28:0];//[28:7] [6:0]  
    assign {we_i,wvalid_i,waddr_i,wtag_i,w_predic_target_i} = w_ibus;

    assign re = we_i&&(waddr_i==btb_raddr_i) ? 1'b0:1'b1;
    btb_ram btb (
      .clka(clk),    // input wire clka
      .ena(1'b1),      // input wire ena
      .wea(we_i),      // input wire [0 : 0] wea
      .addra(waddr_i),  // input wire [6 : 0] addra
      .dina({wvalid_i,wtag_i,w_predic_target_i}),    // input wire [54 : 0] dina 1+22+32=55
      
      .clkb(clk),    // input wire clkb
      .enb(1'b1),      // input wire enb
      .addrb(btb_raddr_i),  // input wire [6 : 0] addrb
      .doutb(btb_rdata)  // output wire [54 : 0] doutb
    );
    
    assign {valid,btb_tag,btb_branch_target_o}= !re ? {wvalid_i,wtag_i,w_predic_target_i} : btb_rdata;//1+22+32=55
    
    //hit or not
    assign hit_o=valid &&(btb_tag==pc_tag_i)?1'b1:1'b0;


endmodule