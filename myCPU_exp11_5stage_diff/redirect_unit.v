module redirect_unit(
    // ID�׶���Ϣ
    input  wire [4:0]  id_rj,
    input  wire [4:0]  id_rk,
    // EX�׶���Ϣ
    input  wire        ex_gr_we,
    input  wire [4:0]  ex_dest,
    
    // MEM�׶���Ϣ  
    input  wire        mem_gr_we,
    input  wire [4:0]  mem_dest,
    
    // WB�׶���Ϣ
    input  wire        wb_gr_we,
    input  wire [4:0]  wb_dest,
    
    // �ض�������ź�
    output reg  [1:0]  rj_redirect,
    output reg  [1:0]  rk_redirect
);


// rj�ض����߼�
always @(*) begin
    if (ex_gr_we && ex_dest != 5'b0 && ex_dest == id_rj) begin
        rj_redirect = 2'b01;  // ��EX�׶��ض���
    end else if ((mem_gr_we && mem_dest != 5'b0 && mem_dest == id_rj)) begin
        rj_redirect = 2'b10;  // ��MEM�׶��ض���
    end else if (wb_gr_we && wb_dest != 5'b0 && wb_dest == id_rj) begin
        rj_redirect = 2'b11;  // ��WB�׶��ض���
    end else begin
        rj_redirect = 2'b00;  // ���ض���
    end
end

// rk/rd�ض����߼�
always @(*) begin
    if (ex_gr_we && ex_dest != 5'b0 && ex_dest == id_rk) begin
        rk_redirect = 2'b01;  // ��EX�׶��ض���
    end else if ((mem_gr_we && mem_dest != 5'b0 && mem_dest == id_rk)) begin
        rk_redirect = 2'b10;  // ��MEM�׶��ض���
    end else if (wb_gr_we && wb_dest != 5'b0 && wb_dest == id_rk) begin
        rk_redirect = 2'b11;  // ��WB�׶��ض���
    end else begin
        rk_redirect = 2'b00;  // ���ض���
    end
end

endmodule