`timescale 1ns / 1ps
`include "myCPU.vh"
`include "Bp_Define.vh"  
module Branch(
    input  wire                        clk,
    input  wire                        reset,

    input  wire                        branch_valid_i,      
    input  wire [`BRANCH_TYPE_LEN-1:0] branch_type_i,    
    input  wire [31:0]                 rj_value_i,       
    input  wire [31:0]                 rkd_value_i,        
    input  wire [31:0]                 pc_i,             
    input  wire [31:0]                 br_b_target_i,    
    input  wire [31:0]                 jirl_offs_i,      
    
    // bp in 
    input  wire [`PhtStateWidth-1:0]   pht_curr_state_i, 
    input  wire                        btb_hit_i,         
    input  wire [31:0]                 predict_target_i,  
    input  wire                        predict_taken_i,  
    
    // branch out 
    output wire                        branch_taken_o,   
    output wire                        branch_unwtr_o,
    output wire [31:0]                 branch_target_o,   
    output wire [31:0]                 branch_pc_o,      
    output wire                        branch_valid_o,
    output wire                        branch_flush_o,   
    output wire                        branch_flush_pc_o,
    output wire [31:0]                 branch_flush_pc_val_o,
    
    // to bp
    output wire [`PhtWbusWidth-1:0]    pht_wbus_o,       // PHT
    output wire [`BtbWbusWidth-1:0]    btb_wbus_o        // BTB
);

    // inst signals 
    wire        rj_eq_rkd;
    wire        rj_lt_rkd;
    wire        rj_ge_rkd;
    wire        rj_ltu_rkd;
    wire        rj_geu_rkd;
    
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_blt;
    wire        inst_bge;
    wire        inst_bltu;
    wire        inst_bgeu;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_jirl;
    
    reg         branch_taken_r;
    reg         branch_unwtr;
    reg  [31:0] branch_target_r;
    reg  [31:0] branch_pc_r;
    reg         branch_flush_r;
 
    // pht state
    reg [`PhtStateWidth-1:0] pht_next_state;
    reg                      pht_we;
    
    // btb signals 
    reg                      btb_we;
    reg                      btb_wvalid;
    reg [`BtbTagWidth-1:0]   btb_wtag;
    reg [`BtbAddrWidth-1:0]  btb_waddr;
    reg [31:0]               btb_wtarget;

    assign inst_beq   = (branch_type_i == `BRANCH_BEQ);
    assign inst_bne   = (branch_type_i == `BRANCH_BNE);
    assign inst_blt   = (branch_type_i == `BRANCH_BLT);
    assign inst_bge   = (branch_type_i == `BRANCH_BGE);
    assign inst_bltu  = (branch_type_i == `BRANCH_BLTU);
    assign inst_bgeu  = (branch_type_i == `BRANCH_BGEU);
    assign inst_b     = (branch_type_i == `BRANCH_B);
    assign inst_bl    = (branch_type_i == `BRANCH_BL);
    assign inst_jirl  = (branch_type_i == `BRANCH_JIRL);

    assign rj_eq_rkd  = (rj_value_i == rkd_value_i);
    assign rj_lt_rkd  = ($signed(rj_value_i) < $signed(rkd_value_i));
    assign rj_ge_rkd  = ($signed(rj_value_i) >= $signed(rkd_value_i));
    assign rj_ltu_rkd = (rj_value_i < rkd_value_i);
    assign rj_geu_rkd = (rj_value_i >= rkd_value_i);

    // branch choose 
    always @(*) begin
        if (branch_valid_i) begin
            case (branch_type_i)
                `BRANCH_BEQ:  branch_taken_r = rj_eq_rkd;
                `BRANCH_BNE:  branch_taken_r = !rj_eq_rkd;
                `BRANCH_BLT:  branch_taken_r = rj_lt_rkd;
                `BRANCH_BGE:  branch_taken_r = rj_ge_rkd;
                `BRANCH_BLTU: branch_taken_r = rj_ltu_rkd;
                `BRANCH_BGEU: branch_taken_r = rj_geu_rkd;
                `BRANCH_B:    branch_taken_r = 1'b1;
                `BRANCH_BL:   branch_taken_r = 1'b1;
                `BRANCH_JIRL: branch_taken_r = 1'b1;
                default:      branch_taken_r = 1'b0;
            endcase
        end else begin
            branch_taken_r = 1'b0;
        end
    end
    
    always @(*) begin
        if (branch_valid_i) begin
            case (branch_type_i)
                `BRANCH_BEQ:  branch_unwtr = rj_eq_rkd;
                `BRANCH_BNE:  branch_unwtr = !rj_eq_rkd;
                `BRANCH_BLT:  branch_unwtr = rj_lt_rkd;
                `BRANCH_BGE:  branch_unwtr = rj_ge_rkd;
                `BRANCH_BLTU: branch_unwtr = rj_ltu_rkd;
                `BRANCH_BGEU: branch_unwtr = rj_geu_rkd;
                `BRANCH_B:    branch_unwtr = 1'b1;
                default:      branch_unwtr = 1'b0;
            endcase
        end else begin
                branch_unwtr = 1'b0;
        end
    end
    
    // branch target 
    always @(*) begin
        if (branch_valid_i) begin
            case (branch_type_i)
                `BRANCH_JIRL: branch_target_r = rj_value_i + jirl_offs_i;
                default:      branch_target_r = br_b_target_i;
            endcase
            branch_pc_r = pc_i;
        end else begin
            branch_target_r = 32'b0;
            branch_pc_r = 32'b0;
        end
    end

    // branch flush 
    always @(*) begin
        branch_flush_r = 1'b0;
        
        if (branch_valid_i) begin
            if (predict_taken_i && btb_hit_i && !branch_taken_r) begin
                branch_flush_r = 1'b1;
            end
            else if (predict_taken_i && branch_taken_r && btb_hit_i && 
                    (predict_target_i != branch_target_r)) begin
                branch_flush_r = 1'b1;
            end
        end
    end

    // pht state 
    always @(*) begin
        pht_we = 1'b0;
        pht_next_state = pht_curr_state_i;
        
        if (branch_valid_i) begin
            pht_we = 1'b1;
            // actually taken 
            if (branch_taken_r) begin
                // predict taken 
                if (predict_taken_i) begin
                    case (pht_curr_state_i)
                        `STRONG_NOT_TAKEN: pht_next_state = `WEAK_NOT_TAKEN;
                        `WEAK_NOT_TAKEN:   pht_next_state = `WEAK_TAKEN;
                        `WEAK_TAKEN:       pht_next_state = `STRONG_TAKEN;
                        `STRONG_TAKEN:     pht_next_state = `STRONG_TAKEN;
                        default:           pht_next_state = `WEAK_TAKEN;
                    endcase
                end 
                // predict not taken 
                else begin
                    case (pht_curr_state_i)
                        `STRONG_NOT_TAKEN: pht_next_state = `WEAK_NOT_TAKEN;
                        `WEAK_NOT_TAKEN:   pht_next_state = `WEAK_TAKEN;
                        `WEAK_TAKEN:       pht_next_state = `STRONG_TAKEN;
                        `STRONG_TAKEN:     pht_next_state = `STRONG_TAKEN;
                        default:           pht_next_state = `WEAK_TAKEN;
                    endcase
                end
            end 
            // actually not taken
            else begin
                // predict taken 
                if (predict_taken_i) begin
                    case (pht_curr_state_i)
                        `STRONG_NOT_TAKEN: pht_next_state = `STRONG_NOT_TAKEN;
                        `WEAK_NOT_TAKEN:   pht_next_state = `STRONG_NOT_TAKEN;
                        `WEAK_TAKEN:       pht_next_state = `WEAK_NOT_TAKEN;
                        `STRONG_TAKEN:     pht_next_state = `WEAK_TAKEN;
                        default:           pht_next_state = `WEAK_NOT_TAKEN;
                    endcase
                end 
                // predict not taken 
                else begin
                    case (pht_curr_state_i)
                        `STRONG_NOT_TAKEN: pht_next_state = `STRONG_NOT_TAKEN;
                        `WEAK_NOT_TAKEN:   pht_next_state = `STRONG_NOT_TAKEN;
                        `WEAK_TAKEN:       pht_next_state = `WEAK_NOT_TAKEN;
                        `STRONG_TAKEN:     pht_next_state = `WEAK_TAKEN;
                        default:           pht_next_state = `WEAK_NOT_TAKEN;
                    endcase
                end
            end
        end
    end

    // btb 
    always @(*) begin
        btb_we = 1'b0;
        btb_wvalid = 1'b1; 
        btb_wtag = branch_pc_r[28:7];  // PC[28:7]
        btb_waddr = branch_pc_r[6:0];   // PC[6:0]
        btb_wtarget = branch_target_r;
        
        //actually  taken 
        if (branch_valid_i && branch_taken_r) begin
            // predict not taken 
            if (!predict_taken_i) begin
                btb_we = 1'b1;
            end
            // not hit
            else if (!btb_hit_i) begin
                btb_we = 1'b1;
            end
            // wrong target 
            else if (btb_hit_i && (branch_target_r != predict_target_i)) begin
                btb_we = 1'b1;
            end
        end
    end
    
    // branch out 
    assign branch_taken_o  = branch_taken_r;
    assign branch_unwtr_o  = branch_unwtr;
    assign branch_target_o = branch_target_r;
    assign branch_pc_o     = branch_pc_r;
    assign branch_valid_o  = branch_valid_i;
    assign branch_flush_o  = branch_flush_r;  
    assign branch_flush_pc_o = branch_flush_r & !branch_taken_r;
    assign branch_flush_pc_val_o = pc_i + 32'd4;
    
    // PHT
    assign pht_wbus_o = {
        pht_we,                   
        branch_pc_r[12:3],               
        pht_next_state             
    };

    // BTB
    assign btb_wbus_o = {
        btb_we,                   
        btb_wvalid,               
        btb_waddr,                 // (PC[6:0])
        btb_wtag,                  // (PC[28:7])
        btb_wtarget                
    };

endmodule