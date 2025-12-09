`timescale 1ns / 1ps
`include "myCPU.vh"
`include "Bp_Define.vh"
module IF_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // branch 
    input  wire [`BR_BUS-1:0]          br_bus,
    // from hazard detection
    input  wire                        fs_stall,
    input  wire                        fs_flush,
    // allowin
    input  wire                        ds_allowin,
    output wire                        fs_allowin,
    // outputs
    output wire                        fs_to_ds_valid,
    output wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus,
    // inst sram interface
    output wire                        inst_sram_en,
    output wire [ 3:0]                 inst_sram_we,
    output wire [31:0]                 inst_sram_addr,
    output wire [31:0]                 inst_sram_wdata,
    input  wire [31:0]                 inst_sram_rdata,
    // bp interfaces
    output wire [`IfToBpBusWidth-1:0]  if_to_bp_bus,
    input  wire [`BpBusRd-1:0]         bp_bus_i
);

    reg to_fs_valid;
    reg  fs_valid;
    wire fs_ready_go;
    wire br_taken;
    wire [31:0] br_target;
    wire branch_flush_pc;
    wire [31:0] branch_to_if_pc;
    
    
    reg  [31:0] fs_pc;
    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    // bp signals 
    wire        predict_valid;
    wire        predict_taken;
    wire [`PhtStateWidth-1:0] predict_state;
    wire        btb_hit;
    wire [31:0] predict_target;
    wire        bp_taken;
    
    // to bp 
    wire        bp_en;
    wire [`PcWidth-1:0] bp_pc;


    assign {br_taken, 
            br_target,
            branch_flush_pc,
            branch_to_if_pc} = br_bus;
    
    // bp decode
    assign {predict_valid, predict_taken, predict_state, btb_hit, predict_target} = bp_bus_i;
   
    
    assign bp_taken = predict_valid && predict_taken && btb_hit;
    
    assign fs_ready_go = 1'b1; 
    assign fs_allowin  = (!fs_valid || fs_ready_go && ds_allowin ) && ~fs_stall;
    assign fs_to_ds_valid = fs_valid && fs_ready_go;

    assign seq_pc = fs_pc + 32'h4;
   
    assign nextpc = ~fs_allowin     ?        fs_pc :
                    branch_flush_pc ?        branch_to_if_pc:
                    br_taken        ?        br_target :
                    bp_taken        ?        predict_target : seq_pc;

    assign fs_to_ds_bus = {
        inst_sram_rdata,  //  32
        fs_pc             //  32
    };

    assign inst_sram_en    = fs_allowin && to_fs_valid;
    assign inst_sram_we    = 4'h0;
    assign inst_sram_addr  = nextpc;
    assign inst_sram_wdata = 32'b0;

    assign bp_pc = fs_pc;
    assign bp_en = fs_valid && ~br_taken;
    assign if_to_bp_bus = { bp_en , bp_pc };

    always @(posedge clk) begin
        if(reset) to_fs_valid<=1'd0;
        else      to_fs_valid<=1'd1;
    end
    
    always @(posedge clk) begin
        if (reset || fs_flush) begin
            fs_valid <= 1'b0;
        end 
        else if (fs_allowin) begin
            fs_valid <= to_fs_valid;
        end
        else if(br_taken) begin
            fs_valid <=1'b0;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            fs_pc <= 32'h1bfffffc; 
        end 
        else if (fs_flush) begin
            fs_pc <= 32'd0;
        end 
        else if (fs_allowin && to_fs_valid) begin
            fs_pc <= nextpc;
        end
    end

endmodule