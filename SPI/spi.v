//
//
`define    SIZE     8
module spi (
    input clk,    // Clock
    input rst_n,  // Asynchronous reset active low
    input rd,
    input wr,
    input si,
    input [`SIZE - 1:0] data_in,
    output sclk,
    output so,
    output cs,
    output [`SIZE -1:0] data_out
);

parameter   bit7=4'd0,
            bit6 = 4'd1,
            bit5 = 4'd2,
            bit4 = 4'd3,
            bit3 = 4'd4,
            bit2 = 4'd5,
            bit1 = 4'd6,
            bit0 = 4'd7,
            bit_end = 4'd8;
parameter   bit70 = 4'd0,
            bit60 = 4'd1,
            bit50 = 4'd2,
            bit40 = 4'd3,
            bit30 = 4'd4,
            bit20 = 4'd5,
            bit10 = 4'd6,
            bit00 = 4'd7,
            bit0_end = 4'd8;

wire [`SIZE-1:0] data_out;
reg [`SIZE-1:0] dout_buf;
reg FF;
reg sclk;
reg so;
reg cs;

reg [3:0] send_state;
reg [3:0] receive_state;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        sclk <= 0;
        cs <= 1;
    end 
    else if(rd|wr) begin
        /* code */
        sclk <= ~sclk;
        cs <= 0;
    end
    else begin
        sclk <= 0;
        cs <= 1;
    end
    
end

assign data_out = (FF==1)? dout_buf:8'hz;


always @(posedge clk ) begin 
    if(wr) begin
        send_state <= 4'b0;
        send_data();
    end 
end

always @(posedge clk ) begin 
    if(rd) begin
         receive_state <= bit70;
         FF <= 0;
         receive_data();
    end 
end

task send_data;
    begin
        case (send_state)
            bit7: begin
                    so <= data_in[7];
                    send_state<=bit6;
                 end
            bit6:begin
                so <= data_in[6];
                send_state <= bit5;
            end
            bit5:begin
                so <= data_in[5];
                send_state <= bit4;
            end
            bit4:begin
                so <= data_in[4];
                send_state <= bit3;
            end
            bit3:begin
                so <= data_in[3];
                send_state <= bit2;
            end
            bit2:begin
                so <= data_in[2];
                send_state <= bit1;
            end
            bit1:begin
                so <= data_in[1];
                send_state <= bit0;
            end
            bit0:begin
                so <= data_in[0];
                send_state <= bit_end;
            end
            bit_end : begin
                so <= 1'bz;
                send_state <= bit7;
            end
            default: ;
        endcase
    end
endtask 

task receive_data;
    begin
        case (receive_state)
            bit70:begin
                dout_buf[7] <= si;
                receive_state <= bit60;
            end
            bit60:begin
                dout_buf[6] <= si;
                receive_state <= bit50;
            end
            bit50:begin
                dout_buf[5] <= si;
                receive_state <= bit40;
            end
            bit40:begin
                dout_buf[4] <= si;
                receive_state <= bit30;
            end
            bit30:begin
                dout_buf[3] <= si;
                receive_state <= bit20;
            end
            bit20:begin
                dout_buf[2] <= si;
                receive_state <= bit10;
            end
            bit10:begin
                dout_buf[1] <= si;
                receive_state <= bit00;
            end
            bit00:begin
                dout_buf[0] <= si;
                receive_state <= bit0_end;
            end
            bit0_end:begin
                dout_buf <= 8'hzz;
                receive_state <= bit70;
            end
            default : /* default */;
        endcase
    end
endtask 


endmodule