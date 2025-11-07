`timescale 1ns / 1ps
`include "myCPU.vh"
module IF_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // branch 
    input  wire [`BR_BUS -1:0]         br_bus,
    // from hazard detection
    input  wire                        fs_stall,
    input  wire                        fs_flush,
    // allowin
    input  wire                        ds_allowin,
    input  wire                        fs_allowin,
    // outputs
    output wire                        fs_to_ds_valid,
    output wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus,
    // inst sram interface
    output wire                        inst_sram_en,
    output wire [ 3:0]                 inst_sram_we,
    output wire [31:0]                 inst_sram_addr,
    output wire [31:0]                 inst_sram_wdata,
    input  wire [31:0]                 inst_sram_rdata
);

    reg to_fs_valid;
    reg  fs_valid;
    wire fs_ready_go;
    wire br_taken;
    wire [31:0] br_target;
    
    reg  [31:0] fs_pc;
    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    assign {br_taken,
            br_target} = br_bus;
    
    assign fs_ready_go = 1'b1; 
    assign fs_allowin  = (!fs_valid || fs_ready_go && ds_allowin ) && ~fs_stall;
    assign fs_to_ds_valid = fs_valid && fs_ready_go && ~br_taken;

    assign seq_pc = fs_pc + 32'h4;
    assign nextpc = ~fs_allowin ? fs_pc :
                   br_taken ? br_target : seq_pc;

    assign fs_to_ds_bus = {inst_sram_rdata,  // 63:32
                           fs_pc            // 31:0
                          };

    assign inst_sram_en    = fs_allowin && to_fs_valid;
    assign inst_sram_we    = 4'h0;
    assign inst_sram_addr  = nextpc;
    assign inst_sram_wdata = 32'b0;


    always @(posedge clk) begin
        if(reset) to_fs_valid<=1'd0;
        else      to_fs_valid<=1'd1;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            fs_valid <= 1'b0;
        end else if (fs_allowin) begin
            fs_valid <= to_fs_valid;
        end
        else if(br_taken) begin
            fs_valid <=1'b0;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            fs_pc <= 32'h1bfffffc; 
        end else if (fs_allowin && to_fs_valid) begin
            fs_pc <= nextpc;
            
        end
        
        if(fs_flush) begin 
            fs_valid<=1'b0;
            fs_valid<=32'b0;
        end
        
    end

endmodule
