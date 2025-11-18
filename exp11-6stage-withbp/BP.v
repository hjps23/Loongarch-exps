`timescale 1ns / 1ps
`include"Bp_Define.vh"
module BP(
    input  wire                              clk,
    input  wire                              reset,
    // data in
    input  wire  [`PcWidth -1:0]             pc_i,
    input  wire                              if_allowin_i,
    // data out 
    output wire [`PrToIfBusWidth -1:0]       to_if_obus,
    // wdata
    input  wire  [`IStoBPWbusWidth -1:0]     is_to_ibus
);

    wire [`PhtWbusWidth -1:0]  pht_wbus_i;
    wire [`BtbWbusWidth -1:0]  btb_wbus_i;
    
    // PHT
    wire pht_branch_o;
    wire [`PhtStateWidth -1:0] pht_rdata_o;
    
    // BTB
    wire btb_hit_o;
    wire [`PcWidth -1:0] btb_branch_target_o;
    
    reg predict_valid_o;
    reg bp_valid;
    reg pht_branch_r;
    reg [`PhtStateWidth -1:0] pht_rdata_r;
    reg btb_hit_r;
    reg [`PcWidth -1:0] btb_branch_target_r;

    assign {pht_wbus_i, btb_wbus_i} = is_to_ibus;
    
    assign to_if_obus = {predict_valid_o, pht_branch_r, pht_rdata_r, btb_hit_r, btb_branch_target_r};

    // PHT
    BP_PHT u_bp_pht(
        .clk        (clk),
        .reset      (reset),
        .w_ibus     (pht_wbus_i),
        .raddr_i    (pc_i[12:3]),
        .rdata_o    (pht_rdata_o)
    );
    
    // BTB
    BP_BTB u_bp_btb(
        .clk                  (clk),
        .reset                (reset),
        .pc_i                 (pc_i),
        .w_ibus               (btb_wbus_i),
        .hit_o                (btb_hit_o),
        .btb_branch_target_o  (btb_branch_target_o)
    );
    
    // (state >=2 ) => jump
    assign pht_branch_o = pht_rdata_o[1];
    
    always @(posedge clk) begin
        if (reset) begin
            bp_valid <= 1'b0;
        end else begin
            bp_valid <= if_allowin_i;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            predict_valid_o <= 1'b0;
            pht_branch_r <= 1'b0;
            pht_rdata_r <= `STRONG_NOT_TAKEN;
            btb_hit_r <= 1'b0;
            btb_branch_target_r <= 32'b0;
        end else begin
            predict_valid_o <= bp_valid;
            pht_branch_r <= pht_branch_o;
            pht_rdata_r <= pht_rdata_o;
            btb_hit_r <= btb_hit_o;
            btb_branch_target_r <= btb_branch_target_o;
        end
    end

endmodule