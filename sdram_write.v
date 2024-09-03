module sdram_write(
    //system signals 
    input       sclk;
    input       s_rst_n,
    // enable signals communcation with top module
    input       wr_en,
    output wire  wr_req,
    output reg  flag_wr_end,
    //
    //output reg [3:0]  wr_cmd,
    //output reg [11:0] wr_addr,
    //output reg [1:0]  bank_addr,
    // output 
    //ref_req 
    input       ref_req,
    input       wr_trig,
    //write interfaces 
    output reg [3:0] wr_cmd,
    output reg [11:0] wr_addr,
    output wire  [1:0]  bank_addr,
    output reg [15:0] wr_data,
    //wfifo interface 
    output wire wfifo_rd_en,
    input [7:0] wfifo_rd_data
);
// main code 
//define state 
localparam S_IDLE = 5'b0_0001;
localparam S_REQ  = 5'b0_0010;
localparam S_ACT  = 5'b0_0100;
localparam S_WR   = 5'b0_1000;
localparam S_PRE  = 5'b1_0000;
//sdram command 
localparam CMD_NOP =  4'b0111;
localparam CMD_PRE =  4'b0010;
localparam CMD_AREF=  4'b0001;
localparam CMD_ACT =  4'b0011;
localparam CMD_WR  =  4'b0100;  
reg flag_wr;

reg [4:0] state;

// act end flag 
reg flag_act_end;
reg flag_pre_end;
reg sd_row_end;
reg [1:0]burst_cnt;
reg [1:0]burst_cnt_t;
reg wr_data_end;
//counter 
reg [3:0]act_cnt ; // coutner 16 number 
reg [3:0]break_cnt ; 
reg [6:0]col_cnt;
reg [11:0]row_adddr;
reg [8:0]col_addr;


//main code 
//flag_wr
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        flag_wr <= 1'b0;
    end
    else if (wr_trig == 1'b1 && flag_wr == 1'b0)begin//need to wait to all finiah 
        flag_wr <= 1'b1;
    end
    else if (wr_data_end == 1'b1)begin
        flag_wr <= 1'b0; 
    end
end

//burst_counter 
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        burst_cnt <= 1'b0;
    end
    else if (state == S_WR)begin
        burst_cnt <= burst_cnt + 1'b1;
    end
    else begin
        burst_cnt <= 1'b0; 
    end
end

    
//burst_counter_t 
always @(posedge sclk or negedge s_rst_n)begin
    burst_cnt_t <= burst_cnt ; 
end




// state trainisition 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        state <= s_IDLE;
    end
    else begin 
        case(state)
            S_IDLE: 
                    if(wr_trig == 1'b1)begin
                        state <= S_REQ;
                    end
                    else begin
                        stae <= S_IDLE;
                    end
            S_REQ : 
                    if(wr_en == 1'b1)begin
                        state <= S_ACT; 
                    end
                    else begin 
                        state <= S_REQ;
                    end

            S_ACT : 
                    if(flag_act_end == 1'b1)begin
                        state <= S_WR;
                    end
                    else begin
                        state <= S_ACT;
                    end

            S_WR  :
                    if(wr_data_end == 1'b1)begin//finish write 
                        state <= S_PRE;
                    end
                    else if (ref_req == 1'b1 && burst_cnt_t == 'd3 && flag_wr == 1'b1)begin //auto refresh request ,finish burst then change to pre
                         state <= S_PRE;
                    end
                    else if(sd_row_end == 1'b1 && flag_wr == 1'b1)begin
                        state <= S_PRE;
                    end//sdram switch to next line ,but data not finiah
            S_PRE : 
                    if(flag_pre_end == 1'b1 && flag_wr == 1'b1)begin
                        state <= S_ACT;
                    end
                    else if (ref_req ==1'b1 && flag_wr == 1'b1)begin
                        state <= S_REQ;
                    end
                    else if (flag_wr == 1'b0)begin
                        state <= S_IDLE;
                    end
            default : 
                    state <= S_IDLE;

        endcase 
    end
end
//wr_cmd
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        wr_cmd <= CMD_NOP;
    end
    else begin
        case(state)
            S_ACT : 
                    if (act_cnt == 'd0)begin
                        wr_cmd <= CMD_ACT ;
                    end
                    else begin
                        wr_cmd <= CMD_NOP ;
                    end
            S_WR : 
                    if (burst_cnt == 'd0)begin
                        wr_cmd <= CMD_WR;
                    end
                    else begin
                        wr_cmd <= CMD_NOP;
                    end
            S_PRE : 
                    if(break_cnt == 'd0)begin
                        wr_cmd <= CMD_PRE;
                    end
                    else begin
                        wr_cmd <= CMD_NOP; 
                    end
            default:
                        wr_cmd  <=      CMD_NOP;
        endcase 
    end
end
 




// write addr 
always  @(*) begin
        case(state)
                S_ACT:
                        if(act_cnt == 'd0)begin
                                wr_addr <=      row_addr;
                        end
                        else begin
                                wr_addr <=      'd0;
                        end
                S_WR:   wr_addr <=      {3'b000, col_addr};
                S_PRE:  if(break_cnt == 'd0)begin
                                wr_addr <=      {12'b0100_0000_0000};
                        end else begin
                                wr_addr <=      'd0;
                        end
                default:
                        wr_addr <=      'd0;
        endcase
end
//flag act end 
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        flag_act_end <= 1'b0;
    end
    else if (act_cnt == 'd3)begin
        flag_act_end <= 1'b1;
    end
    else begin
        flag_act_end <= 1'b0;
    end
end
//act _cnt 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        act_cnt <= 'd0;
    end
    else if (state == S_ACT)begin
        act_cnt <= act_cnt + 1'b1;
    end
    else begin
        act_cnt <= 'd0; 
    end

end

//flag pre end 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n==1'b0)begin
        flag_pre_end <= 1'b0;
    end
    else if(break_cnt == 'd3)begin
        flag_pre_end <= 1'b1;
    end
    else begin
        flag_pre_end <= 1'b0;
    end
end
always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
                flag_wr_end     <=      1'b0;
        end
        else if((state == S_PRE && ref_req == 1'b1) ||   //refresh
                 state == S_PRE && flag_wr == 1'b0) begin    
                flag_wr_end     <=      1'b1;
        end
        else begin
                flag_wr_end     <=      1'b0;
        end
end
//break cnt
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        break_cnt <= 'd0;
    end
    else if (state == S_PRE)begin
        break_cnt <= break_cnt + 1'b1;
    end
    else begin
        break_cnt <= 'd0; 
    end

end
//write data end 
always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
                wr_data_end     <=      1'b0;
        end
        else if(row_addr == 'd0 && col_addr == 'd1)begin
        end
                wr_data_end     <=      1'b1;
        else begin
                wr_data_end     <=      1'b0;
        end
end
//col cnt 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        col_cnt <= 1'b0;
    end
    else if (col_addr == 'd511)begin
        col_cnt <= 1'b0;
    end
    else if (burst_cnt_t == 'd3) begin
        col_cnt <= col_cnt + 1'b1;
    end
    else begin
        col_cnt <= 1'b0;
    end
end
//row addr
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        row_addr <= 'd0;
    end
    else if(sd_row_end == 1'b1)begin
        row_addr <= row_addr + 1'b1;
    end
end 
always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)begin
                sd_row_end      <=      1'b0;
        end
        else if(col_addr == 'd509)begin
                sd_row_end      <=      1'b1;
        end
        else begin
                sd_row_end      <=      1'b0;
        end
end
/* testing data
always @(*)begin//looping write 3 5 7  8 
    case(burst_cnt_t)
        0: wr_data <= 'd3;
        1: wr_data <= 'd5;
        2: wr_data <= 'd7;
        3: wr_data <= 'd9;
    endcase 
end*/



//col addr 
assign  col_addr        =       {7'd0, burst_cnt_t};
assign  bank_addr       =       2'b00;
assign  wr_req          =       state[1];
assign  wfifo_rd_en     =       state[3];
assign  wr_data         =       wfifo_rd_data;
endmodule 