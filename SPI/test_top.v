`timescale   1ns / 1ps

`define  HALF_PERIOD 10
`define  SIM_TIME    600
`define  SIZE        8

module test_top ;
    reg clk;    // Clock
    reg rst_n;  // Asynchronous reset active low
    reg rd;
    reg wr;
    reg si;
    reg [`SIZE - 1:0] data_in;

    wire sclk;
    wire so;
    wire cs;
    wire [`SIZE -1:0] data_out;

    reg [`SIZE-1:0] si_buf;

    //generate clk
    initial
    begin
        clk = 0;
        forever #(`HALF_PERIOD) clk = ~clk;
    end

    initial
    begin
        $display("spi test_top start");
        $dumpfile("test_top.vcd");
        $dumpvars(0,test_top);

        data_in = 8'b0101_0011;
        si_buf = 8'b1001_1010;
        //sclk = clk;
        rst_n = 0;
        #(`HALF_PERIOD);
        rst_n = 1;
        wr = 1;
        rd = 1;
        #400 rd = 0;

        #(`SIM_TIME) $finish;
    end

    always @(posedge clk ) begin 
        si_buf = si_buf << 1;
        si <= si_buf[7];
    end

    spi spi_test (clk,rst_n,rd,wr,si,data_in,sclk,so,cs,data_out);

endmodule