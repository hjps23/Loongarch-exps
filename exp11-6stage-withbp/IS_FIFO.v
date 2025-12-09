/*
max two insts write and read 
*/
module IS_FIFO(
    input  wire  clk      ,
    input  wire  reset    ,

    input wire line1_pre_to_now_valid_i,
    input wire line2_pre_to_now_valid_i,
    //from next stage 
    input wire now_allowin_i,
    //error debug signals
    output wire error_o,
    
    output wire allowin_o,
    output wire line1_now_valid_o,
    output wire line2_now_valid_o,
    //from hazard 
    input wire flush_i,  
    //launch signals 
    input wire double_valid_inst_lunch_flag_i ,
    input wire single_valid_inst_lunch_flag_i ,
    input wire zero_valid_inst_lunch_flag_i   ,
    
    //from pre stage 
    input  wire  [`FIFO_DATA_BUS_WD-1:0] pre_to_now_ibus,
    
    output wire  [`FIFO_DATA_BUS_WD-1:0] now_to_next_obus         
);

/***************************************input variable define(输入变量定义)**************************************/
/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/
/***************************************inner variable define(内部变量定义)**************************************/
reg [`FIFO_DATA_BUS_WD-1:0] inst_data_queue[`LAUNCH_QUEUE_WIDTEH-1:0];
reg inst_valid_queue[`LAUNCH_QUEUE_WIDTEH-1:0];
reg [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] queue_head;
reg [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] queue_tail;

reg  [`LAUNCH_QUEUE_LEN_WIDTH-1:0] queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH-1:0] next_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH-1:0] next_sub_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH-1:0] next_add_sub_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH-1:0] queue_len_add_two, queue_len_add_one, queue_len_sub_two, queue_len_sub_one;

wire double_write;
wire single_write;
wire zero_write;
assign double_write = line1_pre_to_now_valid_i & line2_pre_to_now_valid_i;
assign single_write = (line1_pre_to_now_valid_i & ~line2_pre_to_now_valid_i) | (~line1_pre_to_now_valid_i & line2_pre_to_now_valid_i);
assign zero_write   = ~line1_pre_to_now_valid_i & ~line2_pre_to_now_valid_i;

/***************************************inner variable define(错误状态)**************************************/
wire error;
assign error = queue_len > `LAUNCH_QUEUE_MAX_LEN;
assign error_o = error;

/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
// queue head pointer
always @(posedge clk) begin
    if (reset || flush_i) begin
        queue_head <= `LAUNCH_QUEUE_POINTER_WIDTEH'd0;
    end else if (line2_pre_to_now_valid_i & line1_pre_to_now_valid_i & allowin_o) begin
        queue_head <= queue_head + `LAUNCH_QUEUE_POINTER_WIDTEH'd2;
    end else if (line1_pre_to_now_valid_i & allowin_o) begin 
        queue_head <= queue_head + `LAUNCH_QUEUE_POINTER_WIDTEH'd1;
    end else begin
        queue_head <= queue_head;
    end
end

// queue tail pointer
always @(posedge clk) begin
    if (reset || flush_i) begin
        queue_tail <= `LAUNCH_QUEUE_POINTER_WIDTEH'd0;   
    end else if (single_valid_inst_lunch_flag_i) begin 
        queue_tail <= queue_tail + `LAUNCH_QUEUE_POINTER_WIDTEH'd1;
    end else if (double_valid_inst_lunch_flag_i) begin
        queue_tail <= queue_tail + `LAUNCH_QUEUE_POINTER_WIDTEH'd2;
    end else begin
        queue_tail <= queue_tail;
    end
end

// queue storage - read and write operations
wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] write_addr1 = queue_head;
wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] write_addr2 = queue_head + `LAUNCH_QUEUE_POINTER_WIDTEH'd1;
wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] clear_addr1 = queue_tail;
wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] clear_addr2 = queue_tail + `LAUNCH_QUEUE_POINTER_WIDTEH'd1;

wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] launch_addr1;
wire [`LAUNCH_QUEUE_POINTER_WIDTEH-1:0] launch_addr2;

genvar i;
generate 
    for (i = 0; i < `LAUNCH_QUEUE_WIDTEH; i = i + 1) begin : data_loop
        // data storage
        always @(posedge clk) begin
            if (reset || flush_i) begin
                inst_data_queue[i] <= {`FIFO_DATA_BUS_WD{1'b0}};
            end else if (i == write_addr1 && line1_pre_to_now_valid_i && allowin_o) begin 
                inst_data_queue[i] <= pre_to_now_ibus[`LINE_FIFO_DATA_BUS_WD-1:0];
            end else if (i == write_addr2 && line2_pre_to_now_valid_i && allowin_o) begin 
                inst_data_queue[i] <= pre_to_now_ibus[`FIFO_DATA_BUS_WD-1:`LINE_FIFO_DATA_BUS_WD];
            end else begin
                inst_data_queue[i] <= inst_data_queue[i];
            end
        end
        
        // valid bit storage
        always @(posedge clk) begin
            if (reset || flush_i) begin
                inst_valid_queue[i] <= 1'b0;
            end else if (i == write_addr1 && line1_pre_to_now_valid_i && allowin_o) begin  
                inst_valid_queue[i] <= line1_pre_to_now_valid_i;
            end else if (i == write_addr2 && line2_pre_to_now_valid_i && allowin_o) begin 
                inst_valid_queue[i] <= line2_pre_to_now_valid_i;
            // clear launched instructions
            end else if ((single_valid_inst_lunch_flag_i || double_valid_inst_lunch_flag_i) && i == clear_addr1) begin
                inst_valid_queue[i] <= 1'b0;
            end else if (double_valid_inst_lunch_flag_i && i == clear_addr2) begin
                inst_valid_queue[i] <= 1'b0;
            end else begin
                inst_valid_queue[i] <= inst_valid_queue[i];
            end
        end 
    end 
endgenerate 

assign launch_addr1 = queue_tail;
assign launch_addr2 = queue_tail + `LAUNCH_QUEUE_POINTER_WIDTEH'd1;

// output data - support double launch
assign now_to_next_obus = {inst_data_queue[launch_addr2], inst_data_queue[launch_addr1]};
assign line1_now_valid_o = inst_valid_queue[launch_addr1];
assign line2_now_valid_o = `DOUBLE_LAUNCH ? inst_valid_queue[launch_addr2] : 1'b0;

// calculate queue length changes
assign queue_len_add_two = queue_len + `LAUNCH_QUEUE_LEN_WIDTH'd2;
assign queue_len_add_one = queue_len + `LAUNCH_QUEUE_LEN_WIDTH'd1;
assign queue_len_sub_two = queue_len - `LAUNCH_QUEUE_LEN_WIDTH'd2;
assign queue_len_sub_one = queue_len - `LAUNCH_QUEUE_LEN_WIDTH'd1;

// next queue length calculation
assign next_add_sub_queue_len = 
    double_write ? (double_valid_inst_lunch_flag_i   ? queue_len :
                    single_valid_inst_lunch_flag_i  ? queue_len_add_one : queue_len_add_two) :
    single_write ? (double_valid_inst_lunch_flag_i   ? queue_len_sub_one :
                    single_valid_inst_lunch_flag_i   ? queue_len : queue_len_add_one) :    
                   (double_valid_inst_lunch_flag_i   ? queue_len_sub_two :
                    single_valid_inst_lunch_flag_i  ? queue_len_sub_one : queue_len);   

assign next_sub_queue_len = 
    double_valid_inst_lunch_flag_i ? queue_len_sub_two :
    single_valid_inst_lunch_flag_i ? queue_len_sub_one : queue_len;
                               
assign next_queue_len = allowin_o ? next_add_sub_queue_len : next_sub_queue_len;

// queue length register
always @(posedge clk) begin
    if (reset || flush_i) begin
        queue_len <= `LAUNCH_QUEUE_LEN_WIDTH'd0;
    end else begin
        queue_len <= next_queue_len;
    end      
end

// allow input judgment
assign allowin_o = (queue_len > `LAUNCH_QUEUE_ALLOWIN_CRITICAL_VALUE) ? 1'b0 : 1'b1;

endmodule