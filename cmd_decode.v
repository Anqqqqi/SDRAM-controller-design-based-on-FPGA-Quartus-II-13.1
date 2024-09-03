module cmd_decode (
    //system signals
    input sclk,
    input s_rst_n
    // from uart _rx module 
    input uart_flag,
    input [7:0]uart_data,
    //ouput 
    output wire wr_trig,
    output wire rd_trig,
    output wire wfifo_wr_en,
    output  wire    [ 7:0]  wfifo_data 
);
//parameter
localparam REC_NUM_END = 'd4;
reg [2:0] rec_num;
reg [7:0] cmd_reg;
//main code 
always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
                rec_num <=      'd0;
        end
        else if(uart_flag == 1'b1 && rec_num == 'd0 && uart_data == 8'haa)begin
                rec_num <=      'd0;
        end

        else if(uart_flag == 1'b1 && rec_num == REC_NUM_END)begin
                rec_num <=      'd0;
        end
        else if(uart_flag == 1'b1)begin
            rec_num <=      rec_num + 1'b1;
        end
                
end

always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
            cmd_reg <=      8'h00;
        end
                
        else if(rec_num == 'd0 && uart_flag == 1'b1)begin
                cmd_reg <=      uart_data;
        end
end

assign  wr_trig         =       (rec_num == REC_NUM_END && cmd_reg == 8'h55) ? uart_flag : 1'b0;
assign  rd_trig         =       (rec_num == 'd0 && uart_data == 8'haa) ? uart_flag : 1'b0;
assign  wfifo_wr_en     =       (rec_num >= 'd1) ? uart_flag : 1'b0;
assign  wfifo_data      =       uart_data;

endmodule



