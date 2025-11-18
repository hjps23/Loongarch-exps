`timescale 1ns / 1ps
`include "myCPU.vh"
module WB_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // from hazard detection
    input  wire                        ws_stall,
    input  wire                        ws_flush,
    // allowin
    output wire                        ws_allowin,
    // from ms
    input  wire                        ms_to_ws_valid,
    input  wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    // to rf
    output wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    // to forwarding
    output wire [`WS_TO_IS_FORWARD_BUS -1:0] ws_to_is_forward_bus,
    // trace debug interface
    output wire [31:0]                 debug_wb_pc,
    output wire [ 3:0]                 debug_wb_rf_we,
    output wire [ 4:0]                 debug_wb_rf_wnum,
    output wire [31:0]                 debug_wb_rf_wdata
);

    reg  ws_valid;
    wire ws_ready_go;

    reg  [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;

    wire [31:0] ws_final_result;   
    wire        ws_gr_we;          
    wire [4:0]  ws_dest;          
    wire [31:0] ws_pc;        

    wire        forward_enable;   
    wire        dest_zero;        
    wire        rf_we;
    wire [4:0]  rf_waddr;
    wire [31:0] rf_wdata;

    assign {
        ws_gr_we,         
        ws_dest,        
        ws_final_result,
        ws_pc             
    } = ms_to_ws_bus_r;

    assign ws_to_rf_bus = {
        rf_we,                  // 37 
        rf_waddr,               // 36:32 
        rf_wdata                // 31:0 
    };

    // forward path
    assign dest_zero      = (ws_dest == 5'b0);
    assign forward_enable = ws_gr_we & ~dest_zero & ws_valid;
    assign ws_to_is_forward_bus = {forward_enable, ws_dest, ws_final_result};

    assign rf_we    = ws_gr_we && ws_valid;
    assign rf_waddr = ws_dest;
    assign rf_wdata = ws_final_result;
    
    // trace debug interface
    assign debug_wb_pc       = ws_pc;
    assign debug_wb_rf_we    = {4{ws_gr_we && ws_valid}};
    assign debug_wb_rf_wnum  = ws_dest;
    assign debug_wb_rf_wdata = ws_final_result;

    assign ws_ready_go = 1'b1;
    assign ws_allowin  = (!ws_valid || ws_ready_go) && ~ws_stall;  

    always @(posedge clk) begin
        if (reset || ws_flush) begin
            ws_valid <= 1'b0;
        end else if (ws_allowin) begin
            ws_valid <= ms_to_ws_valid;
        end
    end
    
    always @(posedge clk) begin
        if (reset || ws_flush) begin
            ms_to_ws_bus_r <= {`MS_TO_WS_BUS_WD{1'b0}};
        end 
        else if (ms_to_ws_valid && ws_allowin) begin
            ms_to_ws_bus_r <= ms_to_ws_bus;
        end
    end

endmodule