`timescale 1ns / 1ps
`include "myCPU.vh"
`include "Bp_Define.vh"  
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire        reset;
    wire        fs_allowin;
    wire        ds_allowin;
    wire        IQ_allowin;
    wire        es_allowin;
    wire        ms_allowin;
    wire        ws_allowin;
    
    wire        fs_to_ds_valid;
    wire        ds_to_is_valid;
    wire        is_to_es_valid;
    wire        es_to_ms_valid;
    wire        ms_to_ws_valid;
    
    // hazard detection signals 
    wire        fs_stall, ds_stall, is_stall, es_stall, ms_stall, ws_stall;
    wire        fs_flush, ds_flush, is_flush, es_flush, ms_flush, ws_flush;
    
    // bus interfaces
    wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
    wire [`DS_TO_IS_BUS_WD -1:0] ds_to_is_bus;
    wire [`IS_TO_ES_BUS_WD -1:0] is_to_es_bus;
    wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
    wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
    
    // forward bus
    wire [`ES_TO_IS_FORWARD_BUS -1:0] es_to_is_forward_bus;
    wire [`MS_TO_IS_FORWARD_BUS -1:0] ms_to_is_forward_bus;
    wire [`WS_TO_IS_FORWARD_BUS -1:0] ws_to_is_forward_bus;
    wire [`MS_TO_ES_FORWARD_BUS -1:0] ms_to_es_forward_bus;
    wire [`WS_TO_RF_BUS_WD -1:0]     ws_to_rf_bus;
    
    // hazard bus
    wire [`IS_TO_HAZARD_BUS_WD -1:0] is_to_hazard_bus;
    wire [`ES_TO_HAZARD_BUS_WD -1:0] es_to_hazard_bus;
    wire [`MS_TO_HAZARD_BUS_WD -1:0] ms_to_hazard_bus;
    
    // branch bus
    wire [`BR_BUS -1:0] br_bus;
    
    // BP signals 
    wire [`PcWidth-1:0]            bp_pc_i;
    wire [`BpToIfBusWidth-1:0]     bp_to_if_bus;
    wire [`IfToBpBusWidth-1:0]     if_to_bp_bus;
    wire [`IStoBPWbusWidth-1:0]    is_to_bp_bus;
    
    assign reset = ~resetn;

    
    BP u_bp(
        .clk            (clk),
        .reset          (reset),
        // data in
        .if_bus_i       (if_to_bp_bus),
        .if_allowin_i   (fs_allowin),
        // data out 
        .to_if_obus     (bp_to_if_bus),
        // wdata
        .is_to_ibus     (is_to_bp_bus)
    );

    IF_Stage if_stage(
        .clk                (clk),
        .reset              (reset),
        // branch 
        .br_bus             (br_bus),
        // from hazard detection
        .fs_stall           (fs_stall),
        .fs_flush           (fs_flush),
        // allowin
        .ds_allowin         (ds_allowin),
        .fs_allowin         (fs_allowin),
        // outputs
        .fs_to_ds_valid     (fs_to_ds_valid),
        .fs_to_ds_bus       (fs_to_ds_bus),
        // inst sram interface
        .inst_sram_en       (inst_sram_en),
        .inst_sram_we       (inst_sram_we),
        .inst_sram_addr     (inst_sram_addr),
        .inst_sram_wdata    (inst_sram_wdata),
        .inst_sram_rdata    (inst_sram_rdata),
        // bp interfaces 
        .if_to_bp_bus       (if_to_bp_bus),
        .bp_to_if_bus       (bp_to_if_bus)
    );

    ID_Stage id_stage(
        .clk                (clk),
        .reset              (reset),
        // branch 
        .br_bus             (br_bus),
        // from hazard detection
        .ds_stall           (ds_stall),
        .ds_flush           (ds_flush),
        // allowin
        .IQ_allowin         (IQ_allowin),
        .ds_allowin         (ds_allowin),
        // from fs
        .fs_to_ds_valid     (fs_to_ds_valid),
        .fs_to_ds_bus       (fs_to_ds_bus),
        // to is
        .ds_to_is_valid     (ds_to_is_valid),
        .ds_to_is_bus       (ds_to_is_bus)
    );

    IS_Stage is_stage(
        .clk                        (clk),
        .reset                      (reset),
        // from hazard detection
        .is_stall                   (is_stall),
        .is_flush                   (is_flush),
        // allowin
        .es_allowin                 (es_allowin),
        .IQ_allowin                 (IQ_allowin),
        // branch 
        .br_bus                     (br_bus),
        // from ds
        .ds_to_is_valid             (ds_to_is_valid),
        .ds_to_is_bus               (ds_to_is_bus),
        // to es
        .is_to_es_valid             (is_to_es_valid),
        .is_to_es_bus               (is_to_es_bus),
        // from forwarding 
        .es_to_is_forward_bus       (es_to_is_forward_bus),
        .ms_to_is_forward_bus       (ms_to_is_forward_bus),
        .ws_to_is_forward_bus       (ws_to_is_forward_bus),
        // to rf
        .ws_to_rf_bus               (ws_to_rf_bus),
        // to hazard
        .is_to_hazard_bus           (is_to_hazard_bus),
        // to bp 
        .is_to_bp_bus               (is_to_bp_bus)
    );

    EX_Stage ex_stage(
        .clk                    (clk),
        .reset                  (reset),
        // from hazard detection
        .es_stall               (es_stall),
        .es_flush               (es_flush),
        // allowin
        .ms_allowin             (ms_allowin),
        .es_allowin             (es_allowin),
        // from is
        .is_to_es_valid         (is_to_es_valid),
        .is_to_es_bus           (is_to_es_bus),
        // from ms 
        .ms_to_es_forward_bus   (ms_to_es_forward_bus),
        // to ms
        .es_to_ms_valid         (es_to_ms_valid),
        .es_to_ms_bus           (es_to_ms_bus),
        // to forwarding
        .es_to_is_forward_bus   (es_to_is_forward_bus),
        // data sram interface
        .data_sram_en           (data_sram_en),
        .data_sram_addr         (data_sram_addr),
        // to hazard
        .es_to_hazard_bus       (es_to_hazard_bus)
    );

    MEM_Stage mem_stage(
        .clk                    (clk),
        .reset                  (reset),
        // from hazard detection
        .ms_stall               (ms_stall),
        .ms_flush               (ms_flush),
        // allowin
        .ws_allowin             (ws_allowin),
        .ms_allowin             (ms_allowin),
        // from es
        .es_to_ms_valid         (es_to_ms_valid),
        .es_to_ms_bus           (es_to_ms_bus),
        // to es 
        .ms_to_es_forward_bus   (ms_to_es_forward_bus),
        // to ws
        .ms_to_ws_valid         (ms_to_ws_valid),
        .ms_to_ws_bus           (ms_to_ws_bus),
        // to forwarding
        .ms_to_is_forward_bus   (ms_to_is_forward_bus),
        // data sram interface
        .data_sram_rdata        (data_sram_rdata),
        .data_sram_we           (data_sram_we),
        .data_sram_wdata        (data_sram_wdata),
        // to hazard
        .ms_to_hazard_bus       (ms_to_hazard_bus)
    );

    WB_Stage wb_stage(
        .clk                    (clk),
        .reset                  (reset),
        // from hazard detection
        .ws_stall               (ws_stall),
        .ws_flush               (ws_flush),
        // allowin
        .ws_allowin             (ws_allowin),
        // from ms
        .ms_to_ws_valid         (ms_to_ws_valid),
        .ms_to_ws_bus           (ms_to_ws_bus),
        // to rf
        .ws_to_rf_bus           (ws_to_rf_bus),
        // to forwarding
        .ws_to_is_forward_bus   (ws_to_is_forward_bus),
        // trace debug interface
        .debug_wb_pc            (debug_wb_pc),
        .debug_wb_rf_we         (debug_wb_rf_we),
        .debug_wb_rf_wnum       (debug_wb_rf_wnum),
        .debug_wb_rf_wdata      (debug_wb_rf_wdata)
    );

    hazard_detection_unit u_hazard_unit(
        .is_to_hazard_bus   (is_to_hazard_bus),
        .es_to_hazard_bus   (es_to_hazard_bus),
        .ms_to_hazard_bus   (ms_to_hazard_bus),
        .fs_stall           (fs_stall),
        .ds_stall           (ds_stall),
        .is_stall           (is_stall),
        .es_stall           (es_stall),
        .ms_stall           (ms_stall),
        .ws_stall           (ws_stall),
        .fs_flush           (fs_flush),
        .ds_flush           (ds_flush),
        .is_flush           (is_flush),
        .es_flush           (es_flush),
        .ms_flush           (ms_flush),
        .ws_flush           (ws_flush)
    );

endmodule