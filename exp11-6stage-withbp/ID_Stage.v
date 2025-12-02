`timescale 1ns / 1ps
`include "myCPU.vh"
module ID_Stage(
    input  wire                        clk,
    input  wire                        reset,
    // branch 
    input  wire [`BR_BUS -1:0]         br_bus,
    // from hazard detection
    input  wire                        ds_stall,
    input  wire                        ds_flush,
    // allowin
    input  wire                        IQ_allowin,
    output wire                        ds_allowin,
    // from fs
    input  wire                        fs_to_ds_valid,
    input  wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus,
    // to is
    output wire                        ds_to_is_valid,
    output wire [`DS_TO_IS_BUS_WD -1:0] ds_to_is_bus
    
);
wire [31:0] inst;
wire [31:0] ds_pc;
wire [1:0]  st_size;
wire        unsigned_ext_ld;
wire [4:0]  rkd_in;

//branch signals 
wire        inst_is_branch;
wire [`BRANCH_TYPE_LEN -1:0] branch_type;
wire        br_taken;
wire [`BP_INFO_WIDTH-1:0] bp_info;

wire [18:0] alu_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;
wire        need_rk;
wire [4:0]  dest;
wire [31:0] imm;
wire [31:0] br_offs,br_b_target;
wire [31:0] jirl_offs;

wire [5:0]  op_31_26;
wire [3:0]  op_25_22;
wire [1:0]  op_21_20;
wire [4:0]  op_19_15;
wire [4:0]  rd;
wire [4:0]  rj;
wire [4:0]  rk;

wire [4:0]  ui5;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [3:0]  op_21_20_d;
wire [31:0] op_19_15_d;

wire        inst_add_w;
wire        inst_pcaddu12i;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_slti;
wire        inst_sltui;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_andi;
wire        inst_or;
wire        inst_ori;
wire        inst_xor;
wire        inst_xori;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;

wire        inst_mulh;
wire        inst_mulhu;
wire        inst_mul;
wire        inst_div;
wire        inst_mod;
wire        inst_divu;
wire        inst_modu;

wire        inst_blt;
wire        inst_bltu;
wire        inst_bge;
wire        inst_bgeu;

wire        inst_ldb;
wire        inst_ldh;
wire        inst_ldbu;
wire        inst_ldhu;
wire        inst_stb;
wire        inst_sth;

wire        need_ui5;
wire        need_si12;
wire        need_usi12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;


reg  ds_valid;
wire ds_ready_go;

reg [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;

assign {bp_info,
        inst,
        ds_pc} = fs_to_ds_bus_r;
assign br_taken = br_bus[`BR_BUS -1];   

assign ds_ready_go = 1'b1;
assign ds_allowin  = (!ds_valid || ds_ready_go && IQ_allowin) && ~ds_stall;
assign ds_to_is_valid = ds_valid && ds_ready_go ;

assign op_31_26  = inst[31:26];
assign op_25_22  = inst[25:22];
assign op_21_20  = inst[21:20];
assign op_19_15  = inst[19:15];

assign rd   = inst[ 4: 0];
assign rj   = inst[ 9: 5];
assign rk   = inst[14:10];

assign ui5  = inst[14:10];
assign i12  = inst[21:10];
assign i20  = inst[24: 5];
assign i16  = inst[25:10];
assign i26  = {inst[ 9: 0], inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];

assign inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];  
assign inst_slti      = op_31_26_d[6'h00] & op_25_22_d[4'h8];  
assign inst_sltui     = op_31_26_d[6'h00] & op_25_22_d[4'h9];  
assign inst_andi      = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori       = op_31_26_d[6'h00] & op_25_22_d[4'he];  
assign inst_xori      = op_31_26_d[6'h00] & op_25_22_d[4'hf]; 
assign inst_sll       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];  
assign inst_srl       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];  
assign inst_sra       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];  

assign inst_mul  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulhu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_divu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_modu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];

assign inst_blt   = op_31_26_d[6'h18];  
assign inst_bge   = op_31_26_d[6'h19];  
assign inst_bltu  = op_31_26_d[6'h1a];  
assign inst_bgeu  = op_31_26_d[6'h1b]; 

assign inst_ldb  = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ldh  = op_31_26_d[6'h0a] & op_25_22_d[4'h1]; 
assign inst_ldbu = op_31_26_d[6'h0a] & op_25_22_d[4'h8]; 
assign inst_ldhu = op_31_26_d[6'h0a] & op_25_22_d[4'h9]; 
assign inst_stb  = op_31_26_d[6'h0a] & op_25_22_d[4'h4]; 
assign inst_sth  = op_31_26_d[6'h0a] & op_25_22_d[4'h5];

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ldb 
                    | inst_ldh | inst_ldbu | inst_ldhu | inst_stb | inst_sth;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt|inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltui;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor ;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll;
assign alu_op[ 9] = inst_srli_w | inst_srl;
assign alu_op[10] = inst_srai_w | inst_sra;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12]=  inst_mulh;
assign alu_op[13]=  inst_mulhu;
assign alu_op[14]=  inst_mul;
assign alu_op[15]=  inst_div;
assign alu_op[16]=  inst_mod;
assign alu_op[17]=  inst_divu;
assign alu_op[18]=  inst_modu;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui
                     | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu | inst_stb | inst_sth ;
assign need_usi12 =  inst_andi   | inst_ori  | inst_xori;
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_si12 ? {{20{i12[11]}}, i12[11:0]} :
             need_usi12 ? {20'b0,i12[11:0]}         :
             need_ui5  ? {{27'b0,ui5[4:0]}}  : 32'h4;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_stb | inst_sth;

assign need_rk       =  inst_add_w | inst_sub_w | inst_slt | inst_sltu | inst_nor | 
                        inst_and | inst_or | inst_xor | inst_sll | inst_srl | inst_sra |
                        inst_mul | inst_mulh | inst_mulhu | inst_div | inst_mod | inst_divu | inst_modu;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_ldb    | 
                       inst_ldh    | 
                       inst_ldbu   | 
                       inst_ldhu   | 
                       inst_stb    | 
                       inst_sth    |
                       inst_lu12i_w|
                       inst_pcaddu12i |
                       inst_slti   | 
                       inst_sltui  | 
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_jirl   |
                       inst_bl     ;

assign res_from_mem  = inst_ld_w | inst_ldb | inst_ldbu | inst_ldhu | inst_ldh;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_stb & ~inst_sth &  ~inst_beq & ~inst_bne & ~inst_b & 
                      ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
assign mem_we        = inst_st_w |  inst_stb | inst_sth ;
assign dest          = dst_is_r1 ? 5'd1 : rd;

assign st_size         = inst_ldb | inst_ldbu | inst_stb ? 2'b00 :  // byte
                      inst_ldh | inst_ldhu | inst_sth ? 2'b01 :  // half word
                      2'b10;                                     // word
assign unsigned_ext_ld  = inst_ldbu | inst_ldhu;

assign inst_is_branch = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_b | inst_bl | inst_jirl ;
assign branch_type    = inst_beq  ? `BRANCH_TYPE_LEN'd`BRANCH_BEQ  :
                        inst_bne  ? `BRANCH_TYPE_LEN'd`BRANCH_BNE  :
                        inst_blt  ? `BRANCH_TYPE_LEN'd`BRANCH_BLT  :
                        inst_bge  ? `BRANCH_TYPE_LEN'd`BRANCH_BGE  :
                        inst_bltu ? `BRANCH_TYPE_LEN'd`BRANCH_BLTU :
                        inst_bgeu ? `BRANCH_TYPE_LEN'd`BRANCH_BGEU :
                        inst_b    ? `BRANCH_TYPE_LEN'd`BRANCH_B:
                        inst_bl   ? `BRANCH_TYPE_LEN'd`BRANCH_BL :
                        inst_jirl ? `BRANCH_TYPE_LEN'd`BRANCH_JIRL : `BRANCH_TYPE_LEN'd`DEFAULT_BRANCH_TYPE;
                                                   
assign br_b_target = (inst_beq || inst_bne || inst_bl || inst_b || 
                   inst_blt || inst_bge || inst_bltu || inst_bgeu) ? 
                   (ds_pc + br_offs) : 32'd0;

assign rkd_in = src_reg_is_rd ? rd : 
                need_rk       ? rk : 5'd0;
                
assign ds_to_is_bus = {
    bp_info,              //  36
    inst_is_branch,       //  1
    branch_type,          //  4
    br_b_target,          //  32
    jirl_offs,            //  32
    rj,                   //  5
    rkd_in,               //  5
    alu_op,               //  19
    src1_is_pc,           //  1
    src2_is_imm,          //  1
    res_from_mem,         //  1
    gr_we,                //  1
    mem_we,               //  1
    dest,                 //  5
    st_size,              //  2
    unsigned_ext_ld,      //  1
    imm,                  //  32
    ds_pc                 //  32
};


always @(posedge clk) begin
    if (reset || ds_flush) begin
        ds_valid <= 1'b0;
    end
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
    else if (br_taken)  begin
        ds_valid <=1'b0;
    end
end

always @(posedge clk) begin
    if (reset || ds_flush) begin
        fs_to_ds_bus_r <= {`FS_TO_DS_BUS_WD{1'b0}};
    end 
    else if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end

endmodule