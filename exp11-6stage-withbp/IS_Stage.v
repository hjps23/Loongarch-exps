`timescale 1ns / 1ps
`include "myCPU.vh"
module IS_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // from hazard detection
    input  wire                        is_stall,
    input  wire                        is_flush,
    // allowin
    input  wire                        es_allowin,
    output wire                        IQ_allowin,
    // branch 
    output wire [`BR_BUS-1:0]          br_bus,
    // from ds
    input  wire                        ds_to_is_valid,
    input  wire [`DS_TO_IS_BUS_WD-1:0] ds_to_is_bus,
    // to es
    output wire                        is_to_es_valid,
    output wire [`IS_TO_ES_BUS_WD-1:0] is_to_es_bus,
    // from forwarding 
    input  wire [`ES_TO_IS_FORWARD_BUS-1:0] es_to_is_forward_bus,
    input  wire [`MS_TO_IS_FORWARD_BUS-1:0] ms_to_is_forward_bus,
    input  wire [`WS_TO_IS_FORWARD_BUS-1:0] ws_to_is_forward_bus,
    // to rf
    input  wire [`WS_TO_RF_BUS_WD-1:0] ws_to_rf_bus,
    // to hazard
    output wire [`IS_TO_HAZARD_BUS_WD-1:0] is_to_hazard_bus,
    // to bp
    output wire [`IStoBPWbusWidth-1:0] is_to_bp_bus
);

    // Luanch Queue SIGNALS
    wire IQ_allowin;
    wire IQ_flush;
    wire IQ_line1_valid_o;
    wire IQ_line2_valid_o;
    wire [`DS_TO_IS_BUS_WD-1:0] line1_to_is_bus;
    
    // IS Handshaking Signals
    wire is_ready_go;
    wire is_allowin; 
    reg  is_valid;
    
    // Forwarding Signals
    wire [1:0]  rj_redirect, rkd_redirect;
    wire [31:0] rj_value_redirect, rkd_value_redirect;
    wire        es_gr_we;
    wire [4:0]  es_dest;
    wire [31:0] es_forward_data;
    wire        ms_gr_we;
    wire [4:0]  ms_dest;
    wire [31:0] ms_forward_data;
    wire        ws_gr_we;
    wire [4:0]  ws_dest;
    wire [31:0] ws_forward_data;

    // FIFO OUT SIGNALS
    wire        is_inst_is_branch;
    wire [`BRANCH_TYPE_LEN-1:0] is_branch_type;
    wire [31:0] is_br_b_target;
    wire [31:0] is_jirl_offs;
    wire [18:0] is_alu_op;
    wire        is_src1_is_pc;
    wire        is_src2_is_imm;
    wire        is_res_from_mem;
    wire        is_gr_we;
    wire        is_mem_we;
    wire [4:0]  is_dest;
    wire [1:0]  is_st_size;
    wire        is_unsigned_ext_ld;
    wire [31:0] is_imm;
    wire [31:0] is_retpc;
    wire [31:0] is_pc;
    wire [4:0]  is_rj;     
    wire [4:0]  is_rkd;

    // Branch Signals 
    wire        branch_taken;
    wire        branch_taken_unwtr;
    wire [31:0] branch_target;
    wire [31:0] branch_pc;
    wire        branch_valid;
    wire        branch_flush;
    wire        branch_flush_pc;
    wire [31:0] branch_to_if_pc;
    
    // Bp Signals 
    wire [`BP_INFO_WIDTH-1:0] is_bp_info;
    wire [`PhtStateWidth-1:0] predict_state;
    wire                      predict_taken;
    wire                      btb_hit;
    wire [31:0]               predict_target;
    wire [`PhtWbusWidth-1:0]  pht_wbus;
    wire [`BtbWbusWidth-1:0]  btb_wbus;

    // Regfiles Signals
    wire        rf_we;
    wire [4:0]  rf_waddr;
    wire [31:0] rf_wdata;
    wire [4:0]  rf_raddr1, rf_raddr2;
    wire [31:0] rf_rdata1, rf_rdata2;

    assign {es_gr_we, es_dest, es_forward_data} = es_to_is_forward_bus;
    assign {ms_gr_we, ms_dest, ms_forward_data} = ms_to_is_forward_bus;
    assign {ws_gr_we, ws_dest, ws_forward_data} = ws_to_is_forward_bus;
    
    assign {rf_we, rf_waddr, rf_wdata} = ws_to_rf_bus;

    // FIFO
    IS_FIFO u_IS_FIFO(
        .clk                            (clk),
        .reset                          (reset),
        .line1_pre_to_now_valid_i       (ds_to_is_valid),
        .line2_pre_to_now_valid_i       (1'b0), 
        .now_allowin_i                  (),
        .error_o                        (),      
        .allowin_o                      (IQ_allowin),
        .line1_now_valid_o              (IQ_line1_valid_o),
        .line2_now_valid_o              (IQ_line2_valid_o),
        .flush_i                        (IQ_flush || is_flush),
        .double_valid_inst_lunch_flag_i (1'b0),  
        .single_valid_inst_lunch_flag_i (is_allowin),
        .zero_valid_inst_lunch_flag_i   (1'b0),
        .pre_to_now_ibus                (ds_to_is_bus),
        .now_to_next_obus               (line1_to_is_bus)
    );
    
    
    assign IQ_flush = branch_taken;
    
    assign is_ready_go = 1'b1;
    assign is_allowin =~is_stall & (!is_valid || is_ready_go & es_allowin);
    assign is_to_es_valid = is_valid & is_ready_go;
    
    assign {
        is_bp_info,             // 36
        is_inst_is_branch,      // 1
        is_branch_type,         // 4
        is_br_b_target,         // 32
        is_jirl_offs,           // 32
        is_rj,                  // 5
        is_rkd,                 // 5
        is_alu_op,              // 19
        is_src1_is_pc,          // 1
        is_src2_is_imm,         // 1
        is_res_from_mem,        // 1
        is_gr_we,               // 1
        is_mem_we,              // 1
        is_dest,                // 5
        is_st_size,             // 2
        is_unsigned_ext_ld,     // 1
        is_imm,                 // 32
        is_pc                   // 32
    } = line1_to_is_bus;
    
    assign {
        predict_taken,     //   1
        predict_state,     //   2
        btb_hit,           //   1
        predict_target     //   32
    } = is_bp_info;

    assign rf_raddr1 = is_rj;
    assign rf_raddr2 = is_rkd;
    regfile u_regfile(
        .clk    (clk),
        .raddr1 (rf_raddr1),
        .rdata1 (rf_rdata1),
        .raddr2 (rf_raddr2),
        .rdata2 (rf_rdata2),
        .we     (rf_we),
        .waddr  (rf_waddr),
        .wdata  (rf_wdata)
    );

    redirect_unit u_redirect_unit(
        .rj_in           (is_rj),
        .rkd_in          (is_rkd),
        .ex_gr_we        (es_gr_we),
        .ex_dest         (es_dest),
        .mem_gr_we       (ms_gr_we),
        .mem_dest        (ms_dest),
        .wb_gr_we        (ws_gr_we),
        .wb_dest         (ws_dest),
        .rj_redirect     (rj_redirect),
        .rkd_redirect    (rkd_redirect)
    );
    assign rj_value_redirect = (rj_redirect == 2'b01) ? es_forward_data :
                              (rj_redirect == 2'b10) ? ms_forward_data :
                              (rj_redirect == 2'b11) ? ws_forward_data : rf_rdata1;

    assign rkd_value_redirect = (rkd_redirect == 2'b01) ? es_forward_data :
                               (rkd_redirect == 2'b10) ? ms_forward_data :
                               (rkd_redirect == 2'b11) ? ws_forward_data : rf_rdata2;

    Branch u_Branch(
        .clk                (clk),
        .reset              (reset),
        .branch_valid_i     (IQ_line1_valid_o && is_inst_is_branch && ~is_stall),
        .branch_type_i      (is_branch_type),
        .rj_value_i         (rj_value_redirect),
        .rkd_value_i        (rkd_value_redirect),
        .pc_i               (is_pc),
        .br_b_target_i      (is_br_b_target),
        .jirl_offs_i        (is_jirl_offs),
        // bp in 
        .pht_curr_state_i   (predict_state),
        .btb_hit_i          (btb_hit),
        .predict_target_i   (predict_target),
        .predict_taken_i    (predict_taken),
        // branch out 
        .branch_taken_o     (branch_taken),
        .branch_unwtr_o     (branch_taken_unwtr),
        .branch_target_o    (branch_target),
        .branch_pc_o        (branch_pc),
        .branch_valid_o     (branch_valid),
        .branch_flush_o     (branch_flush),
        .branch_flush_pc_o  (branch_flush_pc),
        .branch_flush_pc_val_o(branch_to_if_pc),
        // to bp
        .pht_wbus_o         (pht_wbus),
        .btb_wbus_o         (btb_wbus)
    );

    // Branch Bus 
    assign br_bus = {
        branch_taken,    
        branch_target,
        branch_flush_pc,
        branch_to_if_pc
    };
    
    // To Es Signals 
    assign is_retpc = is_pc;
    assign is_to_es_bus = {
        is_alu_op,              // [191:173] 19
        is_src1_is_pc,          // [172]     1
        is_src2_is_imm,         // [171]     1
        is_res_from_mem,        // [170]     1
        is_gr_we,               // [169]     1
        is_mem_we,              // [168]     1
        is_dest,                // [167:163] 5
        rj_value_redirect,      // [162:131] 32 
        rkd_value_redirect,     // [130:99]  32 
        is_st_size,             // [98:97]   2
        is_unsigned_ext_ld,     // [96]      1
        is_imm,                 // [95:64]   32
        is_retpc,               // [63:32]   32
        is_pc                   // [31:0]    32
    };

    // To Hazard 
    assign is_to_hazard_bus = {
        branch_flush,
        is_rj,                        
        is_rkd                      
    };
    
    // To Bp 
    assign is_to_bp_bus = {
        pht_wbus,  // PHT
        btb_wbus   // BTB
    };
    
    always@(negedge clk) begin
        if (reset || is_flush) begin
            is_valid <= 1'b0;
        end
        else if(branch_taken_unwtr) begin
            is_valid <= 1'b0;
        end 
        else if(is_allowin) begin
            is_valid <= IQ_line1_valid_o;
        end 
    end 
endmodule