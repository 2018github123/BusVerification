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

`include "can.test_define.v"

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
    
    parameter BRP = 2 * (`CAN_TIMING0_BRP + 1);


    // instantiate 
    mcan2 inst_mcan2 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),.nrst(nrst),
        .val(val),.rd(rd),.wdata(wdata[7:0]),.address(address[7:0]),
        .rx0(rx0),.rdata(rdata[7:0]),.clkout(clkout),.nint(nint),
        .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
        .tx1(tx1),.tx1_en(tx1_en),.test(test));

    // =====  initial ======
    initial 
        begin
            xtal1 = 1'b0;
            forever #(`XTAL1_HALF_PERIODE) xtal1 = ~xtal1; // 50 ns cycle
        end

    always@(xtal1 or nxtal1_enable)
        begin
            xtal1_in = xtal1 | nxtal1_enable;
        end  
        
    // ====start task case ====
    initial
        begin
            reset_test();
            transmit_test();
           /* reset_test();
            receive_test(); */        
        end

    // ==== simulate finish ====
    initial
        begin
            #(`CAN_SIMU_TIME) $finish;    
        end
    // ==== task case ====

    task reset_test;
        begin
            $display("Task hardware reset_test ==> ");
            $display("tx0 is %b",tx0);
            $display("rx0 is %b",rx0);
            nrst = 1'b0 ;         
            write_register(8'h1F,`CDR_R);      // Clock Divider
            write_register(8'h08,`OCR_R);      // Output Control
            write_register(8'h04,`RIE_R);      // Interrupt disable
            write_register(8'h00,`MOD_R);      // MODE
            write_register(8'h10,8'h00);       //ACR 0--3
            write_register(8'h11,8'h00);
            write_register(8'h12,8'h00);
            write_register(8'h13,8'h00);
            write_register(8'h14,8'h00);      //AMR 0--3
            write_register(8'h15,8'h00);
            write_register(8'h16,8'h00);
            write_register(8'h17,8'h00);
            write_register(8'h06,8'h00);     // Bus Timing Register:0 
            write_register(8'h07,8'h00);     // Bus Timing Register:1
            nrst = 1'b1;                      //release hardware reset mode  
            repeat(30)@(posedge xtal1_in);
           // $display("check register initial_status"); 
           // read_register(8'h02);$display("SR is 0x%h",rdata);  //SR         
            $display("<== Task hardware reset_test ");
        end
    endtask

    task transmit_test;
        begin
            $display("Task transmit_test ==>");
            $display("nrst is %b",nrst);
            write_register(8'h06,8'h44);   // mod.0 = 1 reset mode , set bus timing patameter
            write_register(8'h07,8'h1C);                        
            write_register(8'h00,8'h00);  // mod.0 = 0 operator mode
            $display("tx0 is %b",tx0);
            $display("check SR register:");
            read_register(8'h02);$display("SR is 0x%h",rdata);  //SR
             $display("SR[2] is %b",rdata[2]);           
           // wait(rdata[2] != 1'b1) $display("SR = %b transmit buffer full,waiting_release",rdata[2]); 
            wait(rdata[2] == 1'b1) $display("SR = %b transmit buffer released",rdata[2]);          
            /* send data to transmit buffer*/
            $display("===========cpu_write_data start============");
            write_register(8'h10,8'h08); // SFF
            write_register(8'h11,8'h00);
            write_register(8'h12,8'h00);
            write_register(8'h13,8'h01);
            write_register(8'h14,8'h02);
            write_register(8'h15,8'h03);
            write_register(8'h16,8'h04);
            write_register(8'h17,8'h05);
            write_register(8'h18,8'h06);
            write_register(8'h19,8'h07);
            write_register(8'h1A,8'h08);
            $display("===========cpu_write_data end =============");
            repeat(5)@(posedge xtal1_in);          
            // locks transit buffer SR.2 = 0
            // set cmr.0 = 1
            $display("tx0 is %b",tx0);
            $display("Transimit Request:");
            write_register(8'h01,8'h01);   // transmit
            $display("tx0 is %b",tx0);
            wait(tx0 == 1'b0) $display("tx0 = 0, start to transmit data");           
            
            read_register(8'h02);            
            //transmit interrupt or SR.2 = 1            
            //can transmit data include 15 bit of CRC
            // set SR.2= 1
            $display("SR[2] is %b",rdata[2]);
            while(rdata[2] != 1'b1) 
                begin   
                    read_register(8'h02);                  
                    $display(" Time now is :%t ; tx0 : %b",$time,tx0);
                end
         
      
            $display("<==========transmit_test end============");
        end
    endtask


    task receive_test;
        begin
            $display("============receive_test start============");
            write_register(8'h06,8'h44);   // mod.0 = 1 reset mode , set bus timing patameter
            write_register(8'h07,8'h1C);    
            write_register(8'h00,8'h00);   // mod.0 = 0 operator mode
            //repeat(BRP)@(posedge xtal1);  
            nxtal1_in = ~xtal1_in; 

            //read 3 bytes  by rx0 
            $display("============read data from rx0============ >");
            receive_SFF_data();
            $display("< ============read data from rx0============");
            //check if receive successfully: SR.0 = 1 or receive interrupt generated
            read_register(8'h02);
            wait(rdata[0]!=1) $display("receiving......");
            wait(rdata[1]==1) $display("receive buffer is full && available to be read");
                      
            //read buffer 10h - 1ch
            $display("======= cpu_read data start ====>");
            read_register(8'h60);$display("data : %h",rdata);
            read_register(8'h61);$display("data : %h",rdata);
            read_register(8'h62);$display("data : %h",rdata);
            read_register(8'h63);$display("data : %h",rdata);
            read_register(8'h64);$display("data : %h",rdata);
            read_register(8'h65);$display("data : %h",rdata);
            read_register(8'h66);$display("data : %h",rdata);
            read_register(8'h67);$display("data : %h",rdata);
            read_register(8'h68);$display("data : %h",rdata);
            read_register(8'h69);$display("data : %h",rdata);
            read_register(8'h6A);$display("data : %h",rdata);
             $display("<======= cpu_read data end ====");
            //release buffer
            write_register(8'h01,8'h04);            
            $display("============receive_test end============");
        end
    endtask 
////////////////////////////////////////////////////////////////////////////////////////    
    task write_register;
        input [7:0] addr;
        input [7:0] data;
        begin
            @(posedge xtal1_in);
          //  $display("write register start");
            #1;
            val = 1'b1;
            rd = 1'b0;
            address = addr;
            wdata = data;
            @(posedge xtal1_in);
            #1;
            val = 1'b0;
            address = 8'hz;
            wdata = 8'hz;
        //    $display("write register end");
        end 
    endtask 
    
   task receive_bit;
        input sbit;
        begin
            #1 rx0 = sbit;
            repeat((`CAN_TIMING1_TSEG1 + `CAN_TIMING1_TSEG2 + 3)*BRP)@(posedge xtal1_in);
        end
   endtask
   
   task read_register;
        input [7:0] addr;
        begin
            @(posedge xtal1_in);
            #1;
            val = 1'b1;
            rd = 1'b1;
            address = addr;    
            @(posedge xtal1_in);
            #1;
            val = 1'b0;
            rd = 1'b0;
            address = 8'hz;
        end     
   endtask
     
   task receive_SFF_data;
        begin      
              $display("receive SFF data ===>");
              receive_bit(0);  // SOF
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // RTR
              receive_bit(0);  // IDE
              receive_bit(0);  // r0
              receive_bit(0);  // DLC
              receive_bit(1);  // DLC
              receive_bit(1);  // DLC
              receive_bit(1);  // DLC
              receive_bit(1);  // CRC
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC stuff
              receive_bit(0);  // CRC 6
              receive_bit(0);  // CRC
              receive_bit(0);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC  stuff
              receive_bit(0);  // CRC 0
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC 5
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC
              receive_bit(1);  // CRC b
              receive_bit(1);  // CRC DELIM
              receive_bit(0);  // ACK
              receive_bit(1);  // ACK DELIM
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // INTER
              receive_bit(1);  // INTER
              receive_bit(1);  // INTER
             $display("<====receive SFF data");
        end 
   endtask
   
  task receive_EFF_data;
        begin
              $display("send EFF data ===>");
              receive_bit(0);  // SOF
              receive_bit(1);  // ID
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID a
              receive_bit(0);  // ID
              receive_bit(1);  // ID
              receive_bit(1);  // ID
              receive_bit(0);  // ID 6
              receive_bit(0);  // ID
              receive_bit(0);  // ID
              receive_bit(0);  // ID 
              receive_bit(1);  // RTR
              receive_bit(1);  // IDE
              receive_bit(0);  // ID 0
              receive_bit(0);  // ID 
              receive_bit(0);  // ID 
              receive_bit(0);  // ID 
              receive_bit(0);  // ID 0
              receive_bit(1);  // ID stuff
              receive_bit(0);  // ID 
              receive_bit(1);  // ID 
              receive_bit(0);  // ID 
              receive_bit(1);  // ID 6
              receive_bit(1);  // ID 
              receive_bit(0);  // ID 
              receive_bit(1);  // ID 
              receive_bit(0);  // ID a
              receive_bit(1);  // ID 1
              receive_bit(0);  // ID 
              receive_bit(1);  // ID 
              receive_bit(0);  // ID 
              receive_bit(1);  // ID 5
              receive_bit(1);  // RTR
              receive_bit(0);  // r1
              receive_bit(0);  // r0
              receive_bit(0);  // DLC
              receive_bit(1);  // DLC
              receive_bit(0);  // DLC
              receive_bit(1);  // DLC
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC
              receive_bit(0);  // CRC 4
              receive_bit(1);  // CRC
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC d
              receive_bit(0);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC
              receive_bit(1);  // CRC 3
              receive_bit(1);  // CRC
              receive_bit(0);  // CRC
              receive_bit(0);  // CRC
              receive_bit(1);  // CRC 9
              receive_bit(1);  // CRC DELIM
              receive_bit(0);  // ACK
              receive_bit(1);  // ACK DELIM
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // EOF
              receive_bit(1);  // INTER
              receive_bit(1);  // INTER
              receive_bit(1);  // INTER
              $display("<=== send EFF data");
        end 
   endtask
     
    // endtask ////////////////////////////////////////////////////////////////////////////
endmodule
