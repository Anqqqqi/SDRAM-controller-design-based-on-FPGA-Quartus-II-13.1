`define SIM

module uart_rx(
    //system input
    input wire sclk,//systm clock
    input wire s_rst_n,//system reset, nedegated vaild
    //uart interface
    input rs232_rx,//uart rx
    //output
    output reg [7:0] rx_data, 
    output reg po_flag
);
`ifndef SIM
localparam BAUD_END = 5207;
 //baud rate counter 5208
 `else
localparam BAUD_END = 28;
`endif

localparam BAUD_M = BAUD_END /2 -1; //baud rate counter 2603
localparam BIT_END = 8; //bit counter 8
// internal signal
reg rx_r1;//delay one clock
reg rx_r2;//delay two clock
reg rx_r3;//delay three clock
reg rx_flag ; //rx flag
reg [12:0] baud_cnt ; //baud rate counter 5208
reg bit_flag ; //bit flag
reg [3:0] bit_cnt ; //bit counter

// catch the nedage edge of rx 
wire rx_neg; //rx negedge
assign rx_neg = ~rx_r2 & rx_r3;//rx negedge
// main module code //打三拍处理
always @(posedge sclk)begin
    rx_r1 <= rs232_rx;
    rx_r2 <= rx_r1; 
    rx_r3 <= rx_r2;
end
// define the rx flag
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        rx_flag <= 1'b0;
    end
    else if (rx_neg == 1'b1)begin
        rx_flag <= 1'b1;
    end
    else if (bit_cnt == 1'd0 && baud_cnt == BAUD_END)begin
        rx_flag <= 1'b0;
    end
end
//baud rate counter
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        baud_cnt <= 13'd0;
    end
    else if (baud_cnt == BAUD_END)begin
        baud_cnt <= 13'd0;
    end
    else if (rx_flag == 1'b1)begin
        baud_cnt <= baud_cnt + 1'b1;
    end
    else begin
        baud_cnt <= 13'd0;
    end
end

//defind the baud_flag 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        bit_flag <= 1'b0;
    end
    else if (baud_cnt == BAUD_M)begin
        bit_flag <= 1'b1;
    end
    else begin
        bit_flag <= 1'b0;
    end
end

//bit counter
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        bit_cnt <= 4'd0;
    end
    else if (bit_flag == 1'b1 && bit_cnt == BIT_END)begin
        bit_cnt <= 4'd0;//IF ORDER **
    end
    else if (bit_flag == 1'b1)begin
        bit_cnt <= bit_cnt+1'b1;
    end
end
//rX data
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        rx_data <= 8'd0;
    end
    else if (bit_flag == 1'b1 && bit_cnt >= 1'd1)begin//
        rx_data <= {rx_r2,rx_data[7:1]};//left shift ,serial to parallel 1bit -> 8bit
    end
end

//PO FLAG
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        po_flag <= 1'd0;
    end
    else if (bit_cnt== BIT_END && bit_flag == 1'b1)begin//
        po_flag <= 1'd1;
    end
    else begin
        po_flag <= 1'd0;
    end
end
endmodule