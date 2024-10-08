`timescale 1ns/1ns
module tb_uart_tx();

reg sclk;
reg s_rst_n;
reg tx_trig;
reg [7:0] tx_data;
wire rs232_tx;//sim input
//initial begin
initial begin 
    sclk = 1;
    s_rst_n <= 0;
    #100
    s_rst_n <=1;
end
always #5 sclk = ~sclk; //10ns one clock cycle

initial begin 
    tx_data <= 8'd0;
    tx_trig <= 0;
    #200
    tx_trig <= 1'b1;
    tx_data <= 8'h55;
    #10
    tx_trig <= 1'b0;
end 


uart_tx uart_tx_inst(
        //system input
        .sclk(sclk),//systm clock
        .s_rst_n(s_rst_n),//system reset, nedegated vaild
        //uart interface
        .rs232_tx(rs232_tx),//uart tx

        .tx_trig(tx_trig),
        .tx_data(tx_data)
);    
endmodule