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
        //input
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
    // mcan2  mcan2_dut1 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),
    //     .nxtal1_enable(nxtal1_enable),.nrst(nrst),
    //     .val(val),.rd(rd),.wdata(wdata),.address(address),
    //     .rx0(rx0),.rdata(rdata),.clkout(clkout),.nint(nint),
    //     .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
    //     .tx1(tx1),.tx1_en(tx1_en),.test(test));

    mcan2 mcan2_dut2 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),
        .nxtal1_enable(nxtal1_enable),.nrst(nrst),
        .val(val),.rd(rd),.wdata(wdata),.address(address),
        .rx0(rx0),.rdata(rdata),.clkout(clkout),.nint(nint),
        .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
        .tx1(tx1),.tx1_en(tx1_en),.test(test));

    always @(tx0) 
      begin
        rx0 = tx0;
      end
    

    // =====  initial ======
    initial 
        begin            
            xtal1 = 1'b0;
            xtal1_in = 1'b0; 
            nxtal1_in = ~xtal1_in;
            nrst = 1'b1;
            nint_in = 1'b1;
            val = 1'b0;
            rd = 1'b0;                     
            forever #(`XTAL1_HALF_PERIODE) xtal1 = ~xtal1; // 50 ns cycle
        end

    always@(xtal1 or nxtal1_enable)
        begin
            //nxtal_enable = 1 xtal1_in off
            //nxtal_enable = 0 xtal1_in on
            xtal1_in = xtal1 | nxtal1_enable;
           // $display("nxtal1_enable is %b,xtal1 is %b,xtal1_in is %b",nxtal1_enable,xtal1,xtal1_in);
        end  
    always @(xtal1_in) 
      begin 
            nxtal1_in = ~xtal1_in;
           // $display("nxtal1_in is %b",nxtal1_in);
      end 
    // ====start task case ====
    initial
        begin
            reset_test();
            //transmit_test();
            //synchronization_test();
            //receive_test();        
            self_reception_test();
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
            repeat(30)@(posedge xtal1);
  
            $display("<== Task hardware reset_test ");
        end
    endtask

    task transmit_test;
        begin
            $display("Task transmit_test ==>");
            write_register(8'h10,`ACR0);       //mod.0 = 1 reset mode , ACR 0--3
            write_register(8'h11,`ACR1);
            write_register(8'h12,`ACR2);
            write_register(8'h13,`ACR3);
            write_register(8'h14,`AMR0);      //AMR 0--3
            write_register(8'h15,`AMR1);
            write_register(8'h16,`AMR2);
            write_register(8'h17,`AMR3);       

            write_register(8'h06,8'h44);   // mod.0 = 1 reset mode , set bus timing patameter
            write_register(8'h07,8'h1C);                        

            repeat(2*BRP)@(posedge xtal1_in) ;

            write_register(8'h00,`CAN_MODE_OPERATOR);  // mod.0 = 0 operator mode
            
            repeat(2*BRP)@(posedge xtal1_in) ;

            repeat(11)receive_bit(1); //

            repeat(10*BRP)@(posedge xtal1_in) ;
            
            $display("check SR register:");
            read_register(8'h02);  //SR          
            while(rdata[2] != 1'b1)
              begin
                  read_register(8'h02);$display("SR is 0x%h",rdata);  //SR
              end
            $display("SR = %b transmit buffer released",rdata[2]);      
            // send data to transmit buffer
            $display("===========cpu_write_data start============");
            // write_register(8'h10,8'h08); // SFF
            // write_register(8'h11,8'h00);
            // write_register(8'h12,8'h00);
            // write_register(8'h13,8'h01);
            // write_register(8'h14,8'h02);
            // write_register(8'h15,8'h03);
            // write_register(8'h16,8'h04);
            // write_register(8'h17,8'h05);
            // write_register(8'h18,8'h06);
            // write_register(8'h19,8'h07);
            // write_register(8'h1A,8'h08);
            write_register(8'h10,8'h01); // SFF  : 0000,0001;0000,0010;1000,0000;0000,0001
            write_register(8'h11,8'h02);
            write_register(8'h12,8'h80);
            write_register(8'h13,8'h01);

            $display("===========cpu_write_data end =============");
            repeat(20*BRP)@(posedge xtal1_in);          

            //
            // read_register(8'h02);
            // while(rdata[0] != 1'b1)
            // begin
            //   read_register(8'h02);
            // end
            // $display("FIFO is full");
            // locks transit buffer SR.2 = 0
            // set cmr.0 = 1
            // $display("tx0 is %b",tx0);
            // $display("Transimit Request:");
            write_register(8'h01,8'h01);   // transmit
            // $display("tx0 is %b",tx0);
           //wait(tx0 == 1'b0) $display("tx0 = 0, start to transmit data");           
            
            read_register(8'h02);            

            //transmit interrupt or SR.2 = 1            
            //can transmit data include 15 bit of CRC
            // set SR.2= 1
            // $display("SR[2] is %b",rdata[2]);
            while(rdata[2] != 1'b1) 
                begin   
                    read_register(8'h02);                  
                    $display("waiting: tx0 : %b",tx0);
                end
              
            $display("<==========transmit_test end============");
        end
    endtask


    task receive_test;
        begin
            $display("============receive_test start============");                     
            $display("rx0 = %b",rx0);          //initial rx0 = x
                       
            write_register(8'h10,`ACR0);       //mod.0 = 1 reset mode , ACR 0--3
            write_register(8'h11,`ACR1);
            write_register(8'h12,`ACR2);
            write_register(8'h13,`ACR3);
            write_register(8'h14,`AMR0);      //AMR 0--3
            write_register(8'h15,`AMR1);
            write_register(8'h16,`AMR2);
            write_register(8'h17,`AMR3);       

            write_register(8'h04,8'h81);   // enable  receive interrupt

            write_register(8'h06,8'h44);     // mod.0 = 1 reset mode , set bus timing patameter
            write_register(8'h07,8'h1C);    
            
            repeat(2*BRP)@(posedge xtal1_in) ;
              
            write_register(8'h00,`CAN_MODE_OPERATOR);   // mod.0 = 0 operator mode   
                    
            repeat(2*BRP)@(posedge xtal1_in) ;
                        
            repeat(11)receive_bit(1);      //set bus free
     
            repeat(10*BRP)@(posedge xtal1_in) ;
            //****************************************************************//
                       
            hard_synchronization();

            //read 3 bytes  by rx0 
            $display("============read data from rx0============ >");
            
            receive_SFF_data();
            
            $display("< ============read data from rx0============");
            
            repeat(10*BRP)@(posedge xtal1_in) ;
            //check if receive successfully: SR.0 = 1 or receive interrupt generated
            
            read_register(8'h02);
            //$display("SR[0] = %b",rdata[0]);
            while(rdata[0] != 1)
                begin
                    read_register(8'h02);                  
                end
             $display("Time now:%t ; SR[0] = %b",$time,rdata[0]);
             
        
            //read buffer 10h - 1ch
            
            $display("======= cpu_read data start ====>");
            // read_register(8'h60);$display("data : %h",rdata);
            // read_register(8'h61);$display("data : %h",rdata);
            // read_register(8'h62);$display("data : %h",rdata);
            // read_register(8'h63);$display("data : %h",rdata);
            // read_register(8'h64);$display("data : %h",rdata);
            // read_register(8'h65);$display("data : %h",rdata);
            // read_register(8'h66);$display("data : %h",rdata);
            // read_register(8'h67);$display("data : %h",rdata);
            // read_register(8'h68);$display("data : %h",rdata);
            // read_register(8'h69);$display("data : %h",rdata);
            // read_register(8'h6A);$display("data : %h",rdata);

            //
            read_register(8'h10);$display("data : %h",rdata);
            read_register(8'h11);$display("data : %h",rdata);
            read_register(8'h12);$display("data : %h",rdata);
            read_register(8'h13);$display("data : %h",rdata);
            read_register(8'h14);$display("data : %h",rdata);
            read_register(8'h15);$display("data : %h",rdata);
            read_register(8'h16);$display("data : %h",rdata);
            read_register(8'h17);$display("data : %h",rdata);
            read_register(8'h18);$display("data : %h",rdata);
            read_register(8'h19);$display("data : %h",rdata);
            read_register(8'h1A);$display("data : %h",rdata);
             $display("<======= cpu_read data end ====");
            //release buffer
            write_register(8'h01,8'h04);                      
            $display("============receive_test end============");
        end
    endtask 

    task self_reception_test;
     
      begin
      $display("========self_reception_test start ==========>>>>");
      write_register(8'h10,`ACR0);       //mod.0 = 1 reset mode , ACR 0--3
      write_register(8'h11,`ACR1);
      write_register(8'h12,`ACR2);
      write_register(8'h13,`ACR3);
      write_register(8'h14,`AMR0);      //AMR 0--3
      write_register(8'h15,`AMR1);
      write_register(8'h16,`AMR2);
      write_register(8'h17,`AMR3);       

      write_register(8'h04,8'h82);     // enable  receive interrupt
      write_register(8'h06,8'h44);     // mod.0 = 1 reset mode , set bus timing patameter
      write_register(8'h07,8'h1C);    

      repeat(2*BRP)@(posedge xtal1_in) ;
      //set test mode: self test mode

      write_register(8'h00,8'h04);
      //write_register(8'h00,8'h00);

      repeat(2*BRP)@(posedge xtal1_in) ;

      repeat(11)receive_bit(1);      //set bus free
     
      repeat(10*BRP)@(posedge xtal1_in) ;

      //cpu write data to mcan2
      $display("check SR register:");
      read_register(8'h02);  //SR          
      while(rdata[2] != 1'b1)
          begin
              read_register(8'h02);$display("SR is 0x%h",rdata);  //SR
          end
      $display("SR = %b transmit buffer released",rdata[2]);      
      // send data to transmit buffer
      $display("===========cpu_write_data start============");
      write_register(8'h10,8'h01); // SFF
      write_register(8'h11,8'h02);
      write_register(8'h12,8'h80);
      write_register(8'h13,8'h01);
      $display("===========cpu_write_data end =============");
      repeat(10*BRP)@(posedge xtal1_in);   

       hard_synchronization();           

      //CMR.4 = 1 && CMR.1 = 1 : simultaneously results in a single-shot transmission 
      write_register(8'h01,8'h10);

      //repeat(1000)@(posedge xtal1_in);
     
      read_register(8'h02); 
      
      while(rdata[2] != 1'b1 )
        begin
            read_register(8'h02);  
        end

      while(rdata[0] != 1)
        begin
          read_register(8'h02);                  
        end
      $display("<<<<<========self_reception_test end ==========");
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
        input rbit;
        begin            
            #1 rx0 = rbit;
           // $display("receive_bit  rx0 is %b",rx0);
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
 
    task hard_synchronization;
      begin
          #1 rx0 = 0;
          repeat (10*BRP) @ (posedge xtal1_in);
          #1 rx0 = 1;
          repeat (10*BRP) @ (posedge xtal1_in);
      end
   endtask 
   
     
   task receive_SFF_data;
        begin      
              $display("receive SFF data ===>");
              receive_bit(0);  // SOF
              receive_bit(0);  // ID10
              receive_bit(0);  // ID9
              receive_bit(0);  // ID8
              receive_bit(0);  // ID7
              receive_bit(1);  // stuff bit
              receive_bit(0);  // ID6
              receive_bit(0);  // ID5
              receive_bit(1);  // ID4
              receive_bit(0);  // ID3
              receive_bit(1);  // ID2
              receive_bit(0);  // ID1
              receive_bit(0);  // ID0
              receive_bit(0);  // RTR
              receive_bit(0);  // IDE
              receive_bit(0);  // r0
              receive_bit(1);  // stuff bit
              receive_bit(0);  // DLC
              receive_bit(0);  // DLC
              receive_bit(0);  // DLC
              receive_bit(1);  // DLC
              receive_bit(0);  // DATA7
              receive_bit(0);  // DATA6
              receive_bit(0);  // DATA5
              receive_bit(0);  // DATA4
              receive_bit(0);  // DATA3
              receive_bit(1);  // stuff bit
              receive_bit(0);  // DATA2
              receive_bit(0);  // DATA1
              receive_bit(1);  // DATA0

              receive_bit(1);  // CRC14
              receive_bit(1);  // CRC13
              receive_bit(1);  // CRC12
              receive_bit(0);  // CRC11
              receive_bit(1);  // CRC10
              receive_bit(1);  // CRC9
              receive_bit(1);  // CRC8
              receive_bit(0);  // CRC7
              receive_bit(1);  // CRC6
              receive_bit(0);  // CRC5
              receive_bit(1);  // CRC4
              receive_bit(0);  // CRC3
              receive_bit(0);  // CRC2
              receive_bit(1);  // CRC1
              receive_bit(1);  // CRC0

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
              receive_bit(1);
              receive_bit(1);
              receive_bit(1);
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
