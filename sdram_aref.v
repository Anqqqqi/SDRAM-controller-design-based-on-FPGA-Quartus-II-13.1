module sdram_aref (
    //system signals 
    input sclk,//50mhz
    input s_rst_n,
    //communicate with ARBIT
    input ref_en,//auto ref enable 
    output wire ref_req,// auto ref request 
    output reg flag_ref_end,// auto ref end flag 
    //other 
    output reg [3:0]aref_cmd,// cmd out , 
    output wire [11:0]sdram_addr
    input flag_init_end
);
//define the parameter and internal signals 
localparam DELAY_15US = 750 ;//15us % 20 ns = 750 
localparam CMD_AREF = 4'b0001;
localparam CMD_NOP = 4'b0111;
localparam CMD_PRE = 4'b0010;
reg [3:0]cmd_cnt;//counter for cmd
reg [9:0]ref_cnt;//counter for AUTO REFRESH 
reg flag_ref ; //flag for AUTO REFRESH internal aref status
// main code 
// ref cnt 计时15us 
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        ref_cnt <= 1'd0;
    end
    else if (ref_cnt >= DELAY_15US)begin
        ref_cnt <= 1'd0;
    end
    else if(flag_init_end == 1'b1)begin
        ref_cnt <= ref_cnt + 1'b1;
    end
end
//internal flag for auto refresh
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        flag_ref <= 1'b0;
    end
    else if (flag_ref_end==1'b1)begin 
        flag_ref <= 1'b0;
    end

    else if(ref_en == 1'b1)begin
        flag_ref <= 1'b1;
    end

end
//cmd counter 
always @(posedge sclk or negedge s_rst_n)begin
    if (s_rst_n == 1'b0)begin
        cmd_cnt <= 10'd0;
    end
    else if (flag_ref == 1'b1)begin
        cmd_cnt <= cmd_cnt + 1'b1;
    end
    else if (flag_ref_end == 1'b1)begin
        cmd_cnt <= 10'd0;
    end
end
// aref_cmd 
always @(posedge sclk or negedge s_rst_n)begin
    if(s_rst_n == 1'b0)begin
        aref_cmd <= CMD_NOP;
    end
    else case(cmd_cnt)
        //1: aref_cmd <= CMD_PRE;
        2: aref_cmd <= CMD_AREF;
        default: aref_cmd <= CMD_NOP;

    endcase
end



assign flag_ref_end = (cmd_cnt >= 'd3) ? 1'b1 : 1'b0;
assign sdram_addr = 12'b0100_0000_0000;
//auto refresh request 
assign ref_req = (ref_cnt >= DELAY_15US) ? 1'b1 : 1'b0;//refresh request 



endmodule