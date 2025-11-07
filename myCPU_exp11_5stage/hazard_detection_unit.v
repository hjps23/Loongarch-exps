`timescale 1ns / 1ps
`include "myCPU.vh"
module hazard_detection_unit(
    input  wire [`DS_TO_HAZARD_BUS_WD -1:0] ds_to_hazard_bus,
    input  wire [`ES_TO_HAZARD_BUS_WD -1:0] es_to_hazard_bus,
    input  wire [`MS_TO_HAZARD_BUS_WD -1:0] ms_to_hazard_bus,

    output reg         fs_stall,
    output reg         ds_stall,
    output reg         es_stall,
    output reg         ms_stall,
    output reg         ws_stall,
    output reg         fs_flush,
    output reg         ds_flush,
    output reg         es_flush,
    output reg         ms_flush,
    output reg         ws_flush
);
    wire [4:0]  ds_rj;
    wire [4:0]  ds_rk;
    wire        ds_src_reg_is_rd;
    wire        ds_br_taken;
    wire        ds_res_from_mem;

    assign {
        ds_rj,            
        ds_rk,              
        ds_src_reg_is_rd,  
        ds_br_taken,        
        ds_res_from_mem    
    } = ds_to_hazard_bus;

    wire [4:0]  es_dest;
    wire        es_div_stall;
    wire        es_has_ld;

    assign {
        es_dest,         
        es_div_stall,      
        es_has_ld           
    } = es_to_hazard_bus;
    
    wire        ms_has_st;
    assign ms_has_st = ms_to_hazard_bus[0];
    
    // st_ld hazard 
    wire st_ld_stall = es_has_ld & ms_has_st;

    // load data hazard 
    wire load_use_hazard = es_has_ld && 
                          ((es_dest == ds_rj) || 
                           (es_dest == ds_rk) || 
                           (ds_src_reg_is_rd && es_dest == ds_rk));

    // control hazard 
    wire control_hazard = ds_br_taken;

    always @(*) begin
        // default 
        fs_stall = 1'b0;
        ds_stall = 1'b0;
        es_stall = 1'b0;
        ms_stall = 1'b0;
        ws_stall = 1'b0;
        fs_flush = 1'b0;
        ds_flush = 1'b0;
        es_flush = 1'b0;
        ms_flush = 1'b0;
        ws_flush = 1'b0;

        // div 
        if (es_div_stall) begin
            fs_stall = 1'b1;
            ds_stall = 1'b1;
            es_stall = 1'b1;
            ms_flush = 1'b1;
        end
        // load data hazard
        else if (load_use_hazard) begin
            fs_stall = 1'b1;
            ds_stall = 1'b1;
            es_flush = 1'b1;
        end 
        // st_ld hazard
        else if (st_ld_stall) begin
            fs_stall = 1'b1;
            ds_stall = 1'b1;
            es_stall = 1'b1;
            ms_flush = 1'b1;
        end 
        // control hazard
        else if (control_hazard) begin
            ds_flush = 1'b0;
        end
    end

endmodule