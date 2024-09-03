module uart_tx(
        //system input
        input sclk,//systm clock
        input s_rst_n,//system reset, nedegated vaild
        //uart interface
        output reg rs232_tx,//uart tx

        input tx_trig,
        input [7:0] tx_data
        //RFIFO
        input  rfifo_empty , 
        output reg rfifo_rd_en,
        input [7:0] rfifo_rd_data 
);
`ifndef SIM
localparam BAUD_END = 5207;
 //baud rate counter 5208
 `else
localparam BAUD_END = 56;
`endif

localparam BAUD_M = BAUD_END /2 -1; //baud rate counter 2603
localparam BIT_END = 8; //bit counter 8
//internal signal
reg [7:0] tx_data_reg;
reg tx_flag;
reg [12:0] baud_cnt;
reg [3:0] bit_cnt;
reg bit_flag;
//reg rs232_tX;
wire                            tx_trig                         ;
reg                             tx_trig_r1                      ;
//main code

//rfifo rd en 
always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
                rfifo_rd_en     <=      1'b0;
        end
        else if(rfifo_empty == 1'b0 && tx_flag == 1'b0 && rfifo_rd_en == 1'b0)begin
                rfifo_rd_en     <=      1'b1;
        end
        else begin
                rfifo_rd_en     <=      1'b0;
        end
end

//tx trig
// tx_trig_r1
always  @(posedge sclk) begin
        tx_trig_r1      <=      tx_trig;
end

//tx data register
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        tx_data_reg <= 8'b0;
    end
    else if (tx_trig == 1'b1 && tx_flag == 1'b1)begin
        tx_data_reg <= rfifo_rd_data;
    end
end
//tx flag
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        tx_flag <= 1'b0;
    end
    else if (tx_trig == 1'b1 && tx_flag == 1'b0)begin
        tx_flag <= 1'b1;
    end
    else if (bit_cnt == BIT_END && baud_cnt == BAUD_END)begin
        tx_flag <= 1'b0;
    end
end
//baud _cnt
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        baud_cnt <= 13'd0;
    end
    else if (baud_cnt == BAUD_END)begin
        baud_cnt <= 13'd0;
    end
    else if (tx_flag == 1'b1)begin
        baud_cnt <= baud_cnt + 1;
    end
    else begin
        baud_cnt <= 13'd0;
    end
end
//bit_flag
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        bit_flag <= 4'd0;
    end
    else if (baud_cnt == BAUD_END)begin
        bit_flag <= 4'd1;
    end
    else begin
        bit_flag <= 4'd0;
    end
end
//bit cnt
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        bit_cnt <= 4'd0;
    end
    else if (bit_flag ==1'b1 && bit_cnt == BIT_END)begin//bit cnt keep 5208 
        bit_cnt <= 4'd0;
    end
    else if (bit_flag==1'b1)begin//
        bit_cnt <= bit_cnt + 1'b1;
    end
    
end
//rs232_tx
always @(posedge sclk or negedge s_rst_n) begin
    if (s_rst_n == 1'b0) begin
        rs232_tx <= 1'b1;
    end else if (tx_flag == 1'b1) begin
        case (bit_cnt)
            0: rs232_tx <= 1'b0;               // Start bit
            1: rs232_tx <= tx_data_reg[0];
            2: rs232_tx <= tx_data_reg[1];
            3: rs232_tx <= tx_data_reg[2];
            4: rs232_tx <= tx_data_reg[3];
            5: rs232_tx <= tx_data_reg[4];
            6: rs232_tx <= tx_data_reg[5];
            7: rs232_tx <= tx_data_reg[6];
            8: rs232_tx <= tx_data_reg[7];
            9: rs232_tx <= 1'b1;               // Stop bit
            default: rs232_tx <= 1'b1;         // Idle state
        endcase
    end else begin
        rs232_tx <= 1'b1;
    end
end
assign  tx_trig =       rfifo_rd_en;


endmodule