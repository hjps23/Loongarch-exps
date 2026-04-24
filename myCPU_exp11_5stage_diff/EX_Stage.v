`include "myCPU.vh"
module EX_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // from hazard detection
    input  wire                        es_stall,
    input  wire                        es_flush,
    // allowin
    input  wire                        ms_allowin,
    output wire                        es_allowin,
    // from ds
    input  wire                        ds_to_es_valid,
    input  wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,
    // to ms
    output wire                        es_to_ms_valid,
    output wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    // to forwarding
    output wire [`ES_TO_DS_FORWARD_BUS -1:0] es_to_ds_forward_bus,
    // data sram interface
    output wire                        data_sram_en,
    output wire [ 3:0]                 data_sram_we,
    output wire [31:0]                 data_sram_addr,
    output wire [31:0]                 data_sram_wdata,
    input  wire [31:0]                 data_sram_rdata,
    // to hazard
    output wire [`ES_TO_HAZARD_BUS_WD -1:0] es_to_hazard_bus
);

    reg  es_valid;
    wire es_ready_go;

    reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;

    wire [18:0] es_alu_op;
    wire        es_src1_is_pc;
    wire        es_src2_is_imm;
    wire        es_res_from_mem;
    wire        es_gr_we;
    wire        es_mem_we;
    wire [4:0]  es_dest;
    wire [31:0] es_rj_value;
    wire [31:0] es_rkd_value;
    wire [1:0]  es_st_size;
    wire        es_unsigned_ext_ld;
    wire [3:0]  es_byte_en;
    wire [31:0] es_store_data;
    wire [31:0] es_imm;
    wire [31:0] es_retpc;
    wire [31:0] es_pc;
    wire [31:0] es_inst;

    wire        div_stall;
    wire        es_has_ld;


    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0] alu_result;

    wire        forward_enable;
    wire        dest_zero;
    

    assign {es_inst,es_alu_op, es_src1_is_pc, es_src2_is_imm, es_res_from_mem, es_gr_we,
            es_mem_we, es_dest, es_rj_value, es_rkd_value, 
            es_st_size, es_unsigned_ext_ld, es_imm,es_retpc,es_pc} = ds_to_es_bus_r;
            

    assign es_ready_go = !div_stall && ~es_stall;
    assign es_allowin  = !es_valid || (es_ready_go && ms_allowin);
    assign es_to_ms_valid = es_valid && es_ready_go;

    assign alu_src1 = es_src1_is_pc ? es_retpc : es_rj_value;
    assign alu_src2 = es_src2_is_imm ? es_imm : es_rkd_value;
    
    alu u_alu(
        .clk        (clk),
        .reset      (reset),
        .es_valid   (es_valid),
        .alu_op     (es_alu_op),
        .alu_src1   (alu_src1),
        .alu_src2   (alu_src2),
        .alu_result (alu_result),
        .div_stall  (div_stall)
    );


    // byte enable and store data generation
    assign es_byte_en =
        (es_st_size == 2'b00) ?  // byte
            (alu_result[1:0] == 2'b00 ? 4'b0001 :
             alu_result[1:0] == 2'b01 ? 4'b0010 :
             alu_result[1:0] == 2'b10 ? 4'b0100 : 4'b1000) :
        (es_st_size == 2'b01) ?  // half word
            (alu_result[1:0] == 2'b00 ? 4'b0011 :
             alu_result[1:0] == 2'b10 ? 4'b1100 : 4'b0000) :
        4'b1111;  // word

    assign es_store_data =
        (es_st_size == 2'b00) ?  // byte
            {4{es_rkd_value[7:0]}} :
        (es_st_size == 2'b01) ?  // half word
            {2{es_rkd_value[15:0]}} :
            es_rkd_value;  // word

    // Forwarding path
    assign dest_zero      = (es_dest == 5'b0);
    assign forward_enable = es_gr_we & ~dest_zero & es_valid;
    assign es_to_ds_forward_bus = {forward_enable, es_dest, alu_result};

    assign data_sram_en    = 1'b1;
    assign data_sram_addr  = alu_result;
    assign data_sram_we    = {4{es_mem_we && es_valid}} & es_byte_en;
    assign data_sram_wdata = es_store_data;
    
    assign es_has_ld       = es_res_from_mem & es_valid;

    assign es_to_ms_bus = {
                           es_inst,
                           data_sram_addr,
                           data_sram_wdata,
                           data_sram_rdata,
                           es_res_from_mem,             //106       1
                           es_gr_we,                    //105       1
                           es_dest,                     // 103:99   5
                           es_unsigned_ext_ld,          // 98       1
                           es_st_size,                  // 97:96    2
                           alu_result,                  // 95:64    32
                           es_rkd_value,                // 63:31    32
                           es_pc                        // 31:0     32
                           };

    assign es_to_hazard_bus = {
                           es_dest,                     // 5
                           div_stall,                   // 1
                           es_has_ld                    // 1
                           };

    always @(posedge clk) begin
        if (reset || es_flush) begin
            es_valid <= 1'b0;
        end else if (es_allowin) begin
            es_valid <= ds_to_es_valid;
        end
    end
    
    always @(posedge clk) begin
        if (reset || es_flush) begin
            ds_to_es_bus_r <= {`DS_TO_ES_BUS_WD{1'b0}};
        end 
        else if (ds_to_es_valid && es_allowin) begin
            ds_to_es_bus_r <= ds_to_es_bus;
        end
    end

endmodule
