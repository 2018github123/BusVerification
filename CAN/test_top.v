// *********************************
// Project Name : *
// Target Device: *
// Tool version : *
// Module name  : 
// Function     :
// Attention    : *
// Version History : *
//**********************************
// Engineer     : 
// Data         : 2019-3-12
// Modification  :
//**********************************
// All rights reserved
//
// *********************************

`define  SFF_MAX_NUM  13
`define  BAUD_RATE    2000 //2000ns

`include "can_define.v"

`timescale 1 ns / 100 ps

module test_top ;
        //inputs
    reg xtal1;    // Clock
    reg xtal1_in; // 
    reg nxtal1_in;
    reg nrst;  // Asynchronous reset active low
    reg val;
    reg rd;
    reg rx0;
    reg nint_in;
    reg test;
    reg [7:0] wdata;
    reg [7:0] address;

    wire clkout;
    wire nint;
    wire nint_en;
    wire tx0;
    wire tx1;
    wire tx0_en;
    wire tx1_en;
    wire nxtal1_enable;
    wire [7:0] rdata;

    integer i;


    // instantiate 
    mcan2 inst_mcan2 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),.nrst(nrst),
        .val(val),.rd(rd),.wdata(wdata[7:0]),.address(address[7:0]),
        .rx0(rx0),.rdata(rdata[7:0]),.clkout(clkout),.nint(nint),
        .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
        .tx1(tx1),.tx1_en(tx1_en),.test(test));

    // =====  initial ======
    initial 
        begin
            $display("========xtal1=====");
            xtal1 = 1'b0;
            forever #25 xtal1 = ~xtal1; // 50 ns cycle
        end

    initial 
        begin
            $display("========xtal1_in=====");
            xtal1_in = 1'b0;
            forever #25 xtal1_in = ~xtal1_in; // 50 ns cycle
        end   

    // ====start task case ====
    initial
        begin
        //    reset_example();
            reset_test();
           // transmit_test();
            receive_test();
        end

    // ==== simulate finish ====
    initial
        begin
            #20000 $finish;    
        end
    // ==== task case ====
   task reset_example;
       begin
         $display("reset example ");
       end
   endtask

    task reset_test;
        begin
            $display("Task hardware reset_test: ==> ");
            nrst <= 1'b0 ;  
            repeat(2)@(posedge xtal1);
            // CLK DIVIDER
            val = 1'b1;
            rd = 1'b0;
            address <= 8'h1F;
            wdata <= `CDR_R;                   // Clock Divider
            repeat(2)@(posedge xtal1);
            //CLOCK Output
            address <= 8'h08;
            wdata <= `OCR_R;                   // Output Control
            repeat(2)@(posedge xtal1);
            //interrupt enable
            address <= 8'h04;
            wdata <= `RIE_R;                   // Interrupt Enable
            repeat(2)@(posedge xtal1);
            //clear receive interrupt enable
           // address <= 8'h04;
           // wdata <= 8'h00;
            //set acceptance filter
            repeat(2)@(posedge xtal1);
            address <= 8'h00;
            wdata <= `MOD_R;                   // MODE
            //ACR AMR
            repeat(2)@(posedge xtal1);            
            address <= 8'h10;
            wdata = 8'h00;
            repeat(2)@(posedge xtal1);
            for(i=1;i<4;i=i+1)
                begin
                    address <= address + 8'h01;
                    repeat(2)@(posedge xtal1);         
                end
            address <= 8'h14;
            repeat(2)@(posedge xtal1);
            for(i=1;i<4;i=i+1)
                begin
                    address <= address + 8'h01;
                    repeat(2)@(posedge xtal1);         
                end
            
            address <= 8'h06;
            wdata <= `BTR0_R;                // Bus Timing Register:0  
            repeat(2)@(posedge xtal1);
            address <= 8'h07;
            wdata <= `BTR1_R;                // Bus Timing Register:0   
            repeat(2)@(posedge xtal1);
            //release reset mode
            address <= 8'h00;
            wdata = `MOD_R;
            repeat(2)@(posedge xtal1);
            
            nrst <= 1'b1 ;
            address <= 8'h00;
            wdata <= `MOD_C; 
            repeat(2)@(posedge xtal1);
            $display("<== Task hardware reset_test ");
        end
    endtask

    task transmit_test;
        begin
            $display("=========transmit_test start=======>");
            nrst = 1'b1;
            val = 1'b1;
            rd = 1'b0;
            baudrate_set();
            //mod reset 
            address = 8'h00;
            wdata = 8'h01;
            repeat(2)@(posedge xtal1);
            //set bus timing parameter
            address = 8'h06;
            wdata = 8'h44;
            repeat(2)@(posedge xtal1);
            address = 8'h07;
            wdata = 8'h45;
            repeat(2)@(posedge xtal1);
            //set mod.0 = 0 ,operating mode
            address = 8'h00;
            wdata = 8'h00;
            repeat(2)@(posedge xtal1);
            //check SR.2 = 1
            rd = 1'b1;
            address = 8'h02;
            #5;     
            wait(rdata[2] == 1'b1) $display("transmit buffer released :rdata[2] is %b",rdata[2]);       
            /* send data to transmit buffer*/
            cpu_write_data();
            // locks transit buffer SR.2 = 0
            // set cmr.0 = 1
            address = 8'h01;
            wdata = 8'h01; 
            #20;
            //transmit interrupt or SR.2 = 1
            
            //can transmit data include 15 bit of CRC
            // set SR.2= 1
            rd = 1'b1;
            address = 8'h02;
            #5;
            if(rdata[2] == 1'b1) 
                begin
                     $display("Transmit interrupt occurred.");
                     if(rdata[3] == 1'b1) $display("Successful transmission.");
                     else  $display("Write data to Transmit buffer.");
                end

            else
                $display("Do you want to abort transmission?");
            
            $display("<==========transmit_test end============");
        end
    endtask

    task cpu_write_data;
        begin
       	    $display("===========cpu_write_data start============");
            rd = 1'b0;
            address = 8'h10;wdata = 8'h08;
            #20;
            address = 8'h11;wdata = 8'h00;
            #20;
            address = 8'h12;wdata = 8'h00;
            #20;
            address = 8'h13;wdata = 8'h01;
            #20;
            address = 8'h14;wdata = 8'h02;
            #20;
            address = 8'h15;wdata = 8'h03;
            #20;
            address = 8'h16;wdata = 8'h04;
            #20;
            address = 8'h17;wdata = 8'h05;
            #20;
            address = 8'h18;wdata = 8'h06;
            #20;
            address = 8'h19;wdata = 8'h07;
            #20;
            address = 8'h1A;wdata = 8'h08;
            #20;
            $display("===========cpu_write_data end =============");
        end
    endtask

    task receive_test;
        reg [7:0] data_mem [0:`SFF_MAX_NUM-1];
       // reg [7:0] rx0_data [0:2];
        integer i;
        integer j;

        begin
            data_mem[0] = 8'h08;data_mem[1] = 8'h00;data_mem[2] = 8'h00;
            data_mem[3] = 8'h01;data_mem[4] = 8'h02;data_mem[5] = 8'h03;
            data_mem[6] = 8'h04;data_mem[7] = 8'h05;data_mem[8] = 8'h06;
            data_mem[9] = 8'h07;data_mem[10] = 8'h08;
            i = 0;
            j = 0;
            $display("============receive_test start============");
            baudrate_set();
            //operate mode MOD.0 = 0
            val = 1'b1;
            rd = 1'b0;
            address = 8'h00;
            wdata = 8'h00;
            #20;
            //read 3 bytes  by rx0 
            $display("============read data from rx0============ >");
            nxtal1_in = ~xtal1_in;
            for(i=0;i<`SFF_MAX_NUM;i = i+1)
                begin
                     for(j=0;j<8;j = j + 1)
                        begin
                            rx0 = data_mem[i][j];
                            #`BAUD_RATE;
                        end
                end
             $display("< ============read data from rx0============");
            //check if receive successfully: SR.0 = 1 or receive interrupt generated
            repeat(3)@(posedge xtal1);
            //check interrupt
            if(nint == 0)
                begin 
                    $display("NINT is low, an interrupt generated");
                    //read register
                    rd = 1'b1;
                    address = 8'h03;
                    #5;
                    if(rdata[0] == 1)
                        begin
                             $display("received interrupt");                               
                        end
                end 
            else 
                begin
                    //SR.0 
                    rd = 1'b1;
                    address = 8'h02;
                    #5;
                    if(rdata[0] == 1) $display("receive buffer is full && available to be read");
                end                   
        
            //read buffer 10h - 1ch
            i = 0;
            address = 8'h10;
            $display("======= repeat_read data start ====");
            repeat(`SFF_MAX_NUM)@(posedge xtal1)
                begin
                    address = address + i;
                    #10;
                    $display("rdata is %h",rdata);
                end
             $display("======= repeat_read data end ====");
            //release buffer
            rd = 1'b0;
            address = 8'h01;
            wdata = 8'h04;
            #20;
            
            $display("============receive_test end============");
        end
    endtask 
////////////////////////////////////////////////////////////////////////////////////////
    task baudrate_set;
        begin
             //mod reset 
            address = 8'h00;
            wdata = 8'h01;
            repeat(2)@(posedge xtal1);
            //set bus timing parameter
            address = 8'h06;
            wdata = 8'h44;
            repeat(2)@(posedge xtal1);
            address = 8'h07;
            wdata = 8'h45;
            repeat(2)@(posedge xtal1);
        end
    endtask 
    task write_register;
        input [7:0] addr;
        input [7:0] data;
        begin
            address = addr;
            wdata = data;
        end 
    endtask 

    endtask 
    // endtask ////////////////////////////////////////////////////////////////////////////
endmodule
