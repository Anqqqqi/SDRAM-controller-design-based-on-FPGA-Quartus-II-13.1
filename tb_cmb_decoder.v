`timescale 1ns/1ns


module tb_cmd_decode;
    reg sclk;
    reg s_rst_n;
    reg uart_flag;
    reg [7:0]uart_data;
    wire wr_trig;
    wire rd_trig;
    wire [7:0] wfifo_data;
    wire wfifo_wr_en;
initial begin
    sclk = 1;
    s_rst_n = 0;
    #100 
    s_rst_n <= 1;

end

always #5 sclk = ~sclk ; 


initial begin
    uart_flag <= 0; 
    uart_data <= 0;
    #200
    uart_flag <= 1;
    uart_data <= 8'h55; //write command 
    #10
    uart_flag <= 0; 
    #200
    uart_flag <= 1;
    uart_data <= 8'h12;// the first data
    #10
    uart_flag <= 0;
    #200
    uart_flag <= 1;
    uart_data <= 8'h34;// the second data
    #10
    uart_flag <= 0;
    #200
    uart_flag <= 1;
    uart_data <= 8'h56;// the third data
    #10
    uart_flag <= 0;
    #200
    uart_flag <= 1;
    uart_data <= 8'h78;// the forth data
    #10
    uart_flag <= 0;
    #200
    uart_flag <= 1;
    uart_data <= 8'haa;//the read common 
    #10
    uart_flag <= 0;
end

cmd_decode cmd_inst (
    //system signals
    .sclk(sclk),
    .s_rst_n(s_rst_n),
    // from uart _rx module 
    .uart_flag(uart_flag),
    .uart_data(uart_data),
    //ouput 
    .wr_trig(wr_trig),
    .rd_trig(rd_trig),
    .wfifo_wr_en(wfifo_wr_en),
    .wfifo_data(wfifo_data) 
);
endmodule