`timescale 1ns / 1ps
`include "myCPU.vh"
module MEM_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // from hazard detection
    input  wire                        ms_stall,
    input  wire                        ms_flush,
    // allowin
    input  wire                        ws_allowin,
    output wire                        ms_allowin,
    // from es
    input  wire                        es_to_ms_valid,
    input  wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    // to es 
    output wire [`MS_TO_ES_FORWARD_BUS -1:0] ms_to_es_forward_bus,
    // to ws
    output wire                        ms_to_ws_valid,
    output wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    // to forwarding
    output wire [`MS_TO_IS_FORWARD_BUS -1:0] ms_to_is_forward_bus,
    // data sram interface
    input  wire [31:0]                 data_sram_rdata,
    output wire [ 3:0]                 data_sram_we,
    output wire [31:0]                 data_sram_wdata,
    //to hazard
    output wire [`MS_TO_HAZARD_BUS_WD -1:0] ms_to_hazard_bus
);

    reg  ms_valid;
    wire ms_ready_go;

    reg  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;

    wire        ms_res_from_mem;      
    wire        ms_gr_we;             
    wire        ms_mem_we;           
    wire [4:0]  ms_dest;              
    wire        ms_unsigned_ext_ld;    
    wire [1:0]  ms_st_size;           
    wire [31:0] ms_alu_result;      
    wire [31:0] ms_rkd_value;      
    wire [31:0] ms_pc;               

    wire [31:0] ms_final_result;      
    wire [31:0] load_data;            
    wire [31:0] load_data_extended;  
    wire [3:0]  byte_en;             
    wire [31:0] store_data;           

    wire        forward_enable;       
    wire        dest_zero;            

    assign {
        ms_res_from_mem,    // 106
        ms_gr_we,           // 105
        ms_mem_we,          // 104
        ms_dest,            // 103:99
        ms_unsigned_ext_ld, // 98
        ms_st_size,         // 97:96
        ms_alu_result,      // 95:64
        ms_rkd_value,       // 63:32
        ms_pc               // 31:0
    } = es_to_ms_bus_r;

    assign byte_en = 
        (ms_st_size == 2'b00) ?  // byte
            (ms_alu_result[1:0] == 2'b00 ? 4'b0001 :
             ms_alu_result[1:0] == 2'b01 ? 4'b0010 :
             ms_alu_result[1:0] == 2'b10 ? 4'b0100 : 4'b1000) :
        (ms_st_size == 2'b01) ?  // half word
            (ms_alu_result[1:0] == 2'b00 ? 4'b0011 :
             ms_alu_result[1:0] == 2'b10 ? 4'b1100 : 4'b0000) : 
        4'b1111;  // word

    // store data
    assign store_data = 
        (ms_st_size == 2'b00) ?  // byte
            {4{ms_rkd_value[7:0]}} :
        (ms_st_size == 2'b01) ?  // half word
            {2{ms_rkd_value[15:0]}} : 
            ms_rkd_value;  // word

    // load data
    assign load_data = 
        (ms_st_size == 2'b00) ?  // byte
            (ms_alu_result[1:0] == 2'b00 ? {24'b0, data_sram_rdata[7:0]} :
             ms_alu_result[1:0] == 2'b01 ? {24'b0, data_sram_rdata[15:8]} :
             ms_alu_result[1:0] == 2'b10 ? {24'b0, data_sram_rdata[23:16]} : 
             {24'b0, data_sram_rdata[31:24]}) :
        (ms_st_size == 2'b01) ?  // half word
            (ms_alu_result[1:0] == 2'b00 ? {16'b0, data_sram_rdata[15:0]} :
             ms_alu_result[1:0] == 2'b10 ? {16'b0, data_sram_rdata[31:16]} : 32'b0) : 
            data_sram_rdata;  // word

    // signed extend
    assign load_data_extended = 
        (ms_st_size == 2'b00 && !ms_unsigned_ext_ld) ?  // signed byte
            {{24{load_data[7]}}, load_data[7:0]} :
        (ms_st_size == 2'b01 && !ms_unsigned_ext_ld) ?  // signed half word
            {{16{load_data[15]}}, load_data[15:0]} :
            load_data;  // unsigned or word

    // final result
    assign ms_final_result = ms_res_from_mem ? load_data_extended : ms_alu_result;

    // forward path 
    assign dest_zero      = (ms_dest == 5'b0);
    assign forward_enable = ms_gr_we & ~dest_zero & ms_valid;
    assign ms_to_is_forward_bus = {forward_enable, ms_dest, ms_final_result};

    // data ram interfaces
    assign data_sram_we    = {4{ms_mem_we && ms_valid}} & byte_en;
    assign data_sram_wdata = store_data;

    //st_ld_stall 
    assign ms_has_st = ms_mem_we & ms_valid;
    
    assign ms_to_hazard_bus = ms_has_st;
    
    assign ms_to_ws_bus = {
        ms_gr_we,          //  [69]    1
        ms_dest,           // [68:64]  5
        ms_final_result,   // [63:32]  32
        ms_pc              // [31:0]  32
    };
    
    assign ms_to_es_forward_bus = {ms_mem_we,
                                   ms_alu_result};

    assign ms_ready_go = 1'b1;
    assign ms_allowin  = (!ms_valid || ms_ready_go && ws_allowin) && ~ms_stall;
    assign ms_to_ws_valid = ms_valid && ms_ready_go;

    always @(posedge clk) begin
        if (reset || ms_flush) begin
            ms_valid <= 1'b0;
        end else if (ms_allowin) begin
            ms_valid <= es_to_ms_valid;
        end
    end
    
    always @(posedge clk) begin
        if (reset || ms_flush) begin
            es_to_ms_bus_r <= {`ES_TO_MS_BUS_WD{1'b0}};
        end 
        else if (es_to_ms_valid && ms_allowin) begin
            es_to_ms_bus_r <= es_to_ms_bus;
        end
    end

endmodule
