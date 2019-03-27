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
    
   // `ifdef TRANSMIT_TEST
    //input
   
    
    
   // `else
    //input
    reg xtal1;      // Clock
    reg xtal1_in;   // 
    reg nxtal1_in;
    reg nrst;       // Asynchronous reset active low
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
   // `endif
    
    reg val0;
    reg rd0;
    reg rx0_0;
    reg [7:0] wdata0;
    reg [7:0] address0;
    wire [7:0] rdata0;
    wire tx0_0;
    wire nint0;
    
    reg val1;
    reg rd1;
    reg [7:0] wdata1;
    reg [7:0] address1;
    wire [7:0] rdata1;
    wire tx0_1;
    wire nint1;
    
    integer i;
    
    parameter BRP = 2 * (`CAN_TIMING0_BRP + 1);

    // instantiate 
   // `ifdef TRANSMIT_TEST
   /*
    mcan2 mcan2_dut1 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),
        .nxtal1_enable(nxtal1_enable),.nrst(nrst),
        .val(val),.rd(rd),.wdata(wdata),.address(address),
        .rx0(rx0),.rdata(rdata),.clkout(clkout),.nint(nint),
        .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
        .tx1(tx1),.tx1_en(tx1_en),.test(test));
        */
    //`else
    mcan2 mcan2_dut2 (.xtal1(xtal1),.xtal1_in(xtal1_in),.nxtal1_in(nxtal1_in),
        .nxtal1_enable(nxtal1_enable),.nrst(nrst),
        .val(val),.rd(rd),.wdata(wdata),.address(address),
        .rx0(rx0),.rdata(rdata),.clkout(clkout),.nint(nint),
        .nint_in(nint_in),.nint_en(nint_en),.tx0(tx0),.tx0_en(tx0_en),
        .tx1(tx1),.tx1_en(tx1_en),.test(test));
    //`endif

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
            #5;
            xtal1_in = xtal1 | nxtal1_enable;
        end  
    always @(xtal1_in) 
      begin 
            nxtal1_in = ~xtal1_in;
      end 
    // ====start task case ====
    initial
        begin
            reset_test();
            //transmit_test();
            //receive_test(); 
                   
            //self_reception_test();        
           /* sleep_mode_test();
            wake_up_test();*/
            //hot_plugin_test();
            interrupt_test();
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
            mode_set(`CAN_MODE_RESET);     
            filter_set();
            btr_set();                        
            repeat(2*BRP)@(posedge xtal1) ;
            mode_set(`CAN_MODE_OPERATOR);                     
            repeat(2*BRP)@(posedge xtal1) ;
            repeat(11)receive_bit(1); //bus free
            repeat(10*BRP)@(posedge xtal1) ;            
            //"check SR register:"
            read_register(8'h02);  //SR          
            while(rdata[2] != 1'b1)
              begin
                  read_register(8'h02);$display("SR is 0x%h",rdata);  //SR
              end
            $display("SR = %b transmit buffer released",rdata[2]);      
            // send data to transmit buffer
            $display("===========cpu_write_data start============");         
            write_register(8'h10,8'h01); // SFF  : 0000,0001;0000,0010;1000,0000;0000,0001
            write_register(8'h11,8'h02);
            write_register(8'h12,8'h80);
            write_register(8'h13,8'h01);
            $display("===========cpu_write_data end =============");
            repeat(20*BRP)@(posedge xtal1_in);          

            // locks transit buffer SR.2 = 0
            // set cmr.0 = 1
            // $display("Transimit Request:");
            //`define TRANSMIT_TEST;
            write_register(8'h01,8'h01);   // transmit
         
            wait(tx0 == 1'b0) $display("tx0 = 0, start to transmit data");
            
           // receive_bit(tx0);  
                       
            read_register(8'h02);            

            //transmit interrupt or SR.2 = 1            
            //can transmit data include 15 bit of CRC
            // set SR.2= 1
            // $display("SR[2] is %b",rdata[2]);
            while(rdata[2] != 1'b1) 
                begin   
                    read_register(8'h02);                  
                end
            //`undef TRANSMIT_TEST;
            $display("<==========transmit_test end============");
        end
    endtask


    task receive_test;
        begin
            $display("============receive_test start============");                     
            $display("rx0 = %b",rx0);          //initial rx0 = x
            mode_set(`CAN_MODE_RESET);                               
            filter_set();
            btr_set(); 
            write_register(8'h04,8'h81);   // enable  receive interrupt
            repeat(2*BRP)@(posedge xtal1_in) ;
            mode_set(`CAN_MODE_OPERATOR);                   
            repeat(2*BRP)@(posedge xtal1_in) ;                        
            repeat(11)receive_bit(1);      //set bus free
            repeat(10*BRP)@(posedge xtal1_in) ;                       
            hard_synchronization();
            receive_SFF_data();
            repeat(10*BRP)@(posedge xtal1_in) ;
            //check if receive successfully: SR.0 = 1 or receive interrupt generated
            read_register(8'h02);
            //$display("SR[0] = %b",rdata[0]);
            while(nint != 0 && rdata[0] != 1)
                begin
                    read_register(8'h02);                  
                end
            // $display("Time now:%t ; SR[0] = %b",$time,rdata[0]);
            //read buffer 10h - 1ch
            $display("======= cpu_read data start ====>");
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
      filter_set();
      btr_set();        
      write_register(8'h04,8'h82);     // enable  receive interrupt
      repeat(2*BRP)@(posedge xtal1_in) ;
      //set test mode: self test mode
      mode_set(`CAN_MODE_SELF_TEST);
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
      read_register(8'h02); 
      while(rdata[2] != 1'b1 )
        begin
            read_register(8'h02);  
        end
      while(rdata[0] != 1)
        begin
          read_register(8'h02);                  
        end       
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
        //release buffer
        write_register(8'h01,8'h04);
        repeat(2*BRP)@(posedge xtal1_in);     
      $display("<<<<<========self_reception_test end ==========");
      end
    endtask 

    task sleep_mode_test;
        begin
         $display("========sleep_mode_test start ==========>>>>");
         write_register(8'h04,8'h00);     // disable  receive interrupt
         repeat(2*BRP)@(posedge xtal1) ;
         // bus free   
         repeat(11)receive_bit(1);
         repeat(10*BRP)@(posedge xtal1) ;
         //if not reset mode, set sleep mode MOR4 = 1       
         write_register(8'h00,`CAN_MODE_SLEEP);
         repeat(10*BRP)@(posedge xtal1);
         wait(nxtal1_enable == 1) $display("set sleep mode successfully");             
         $display("<<<<========sleep_mode_test end ==========");
        end
    endtask
    
    task wake_up_test;
        begin
            $display("======== wake_up_test start ==========>>>>");            
            //now is sleep mode 
            //set sleep mod = 0 or bus activity or a low on nint_in
            write_register(8'h00,`CAN_MODE_OPERATOR);
            repeat(10*BRP)@(posedge xtal1);
            //generate wake-up interrupt
           // read_register(8'h00);$display("data : %h",rdata);
            wait(nxtal1_enable == 0)$display("wake up from sleep mode by setting mod.4 = 0");                   
            $display("<<<<======== wake_up_test end===========");
        end
    endtask
    
    
    task hot_plugin_test;
        begin
            $display("========hot_plugin_test start ==========>>>>");
            //reset mode 
            mode_set(`CAN_MODE_RESET); 
            //enable bus error and receive interrupt
            write_register(8'h04,8'h81);
            repeat(2*BRP)@(posedge xtal1);
            //set ARM[0-3]
              write_register(8'h10,`ACR0);     //mod.0 = 1 reset mode , ACR 0--3
              write_register(8'h11,`ACR1);
              write_register(8'h12,`ACR2);
              write_register(8'h13,`ACR3);
              write_register(8'h14,8'hff);      //AMR 0--3
              write_register(8'h15,8'hff);
              write_register(8'h16,8'hff);
              write_register(8'h17,8'hff);
            //set initial BTR
            write_register(8'h06,`BTR0);     // mod.0 = 1 reset mode , set bus timing patameter
            write_register(8'h07,`BTR1);         
            //set listen only mode
            $display("set listen only mode");
            mode_set(`CAN_MODE_LISTEN_ONLY); 
            repeat(2*BRP)@(posedge xtal1); 
              //set bus free
            repeat(2*BRP)@(posedge xtal1_in) ;
            repeat(11)receive_bit(1);      //set bus free
            repeat(10*BRP)@(posedge xtal1_in) ; 
            //generate interrupt
            //check if receive interrupt
          
            read_register(8'h03);
            fork
                begin                  

                    while((nint != 0 || rdata[0] != 1) && rdata[7] == 1)
                    begin
                        read_register(8'h03);  
                    end
                    
                    receive_SFF_data();
                    
                end
            join
           /*
            $display("set operator mode");
            mode_set(`CAN_MODE_OPERATOR);
            repeat(2*BRP)@(posedge xtal1);
            receive_SFF_data();
            */
            repeat(2*BRP)@(posedge xtal1);
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
            //release buffer
            write_register(8'h01,8'h04);
            $display("<<<<========hot_plugin_test end ==========");
        end
    endtask

    /*
    task bus_off_test;
        begin
            $display("========bus_off_test start ==========>>>>");
            $display("<<<<========bus_off_test end ============");
        end
    endtask
    */
    
    task interrupt_test;
        begin
            $display("========interrupt_test start ==========>>>>");
            /*wake_up_interrupt();
            data_overrun_interrupt();
            transmit_interrupt();*/
           // receive_interrupt();
           // error_passive_interrupt();
            error_warning_interrupt();
            $display("<<<<========interrupt_test end ============");
        end
    endtask 

    task wake_up_interrupt;
      begin
            //enable wake up interrrupt
            enable_interrupt(8'h10);
            repeat(2*BRP)@(posedge xtal1) ;
            read_register(8'h04);$display("EIR is %h",rdata);
            mode_set(`CAN_MODE_OPERATOR);
            repeat(2*BRP)@(posedge xtal1);
            // bus free   
            repeat(11)receive_bit(1);
            repeat(10*BRP)@(posedge xtal1) ;
            //hard_synchronization();
            //sleep
            mode_set(`CAN_MODE_SLEEP);
            repeat(2*BRP)@(posedge xtal1);
            wait(nxtal1_enable == 1) $display("set sleep mode successfully"); 
            //bus activity while sleeping  
            wake_up_sequence();
            //receive interrupt
            wait(nint == 0) $display("wake up interrupt generated successfully"); 
            // nint_in = 0;
            repeat(2*BRP)@(posedge xtal1);
        end
    endtask 

    task wake_up_sequence;
      begin
        //??
            #1 rx0 = 0;
            repeat(BRP)@(posedge xtal1);
            #10 rx0 = 1;
            repeat(9000)@(posedge xtal1);///???
            #1 rx0 = 0;
            repeat(BRP)@(posedge xtal1);            
      end
    endtask 

    task receive_interrupt;
      begin
        //
        mode_set(`CAN_MODE_RESET);
        enable_interrupt(8'h01); 
        filter_set();
        btr_set(); 
        repeat(2*BRP)@(posedge xtal1_in) ;
        mode_set(`CAN_MODE_OPERATOR);                   
        repeat(2*BRP)@(posedge xtal1_in) ;                        
        repeat(11)receive_bit(1);      //set bus free
        repeat(10*BRP)@(posedge xtal1_in) ;                       
        hard_synchronization();
        receive_SFF_data();
        repeat(10*BRP)@(posedge xtal1_in) ;
        //check if receive successfully: SR.0 = 1 or receive interrupt generated
        //read_register(8'h02);
        wait(nint == 0)$display("receive interrupt generated. nint = %b",nint);
         //release buffer
        write_register(8'h01,8'h04);
       repeat(2*BRP)@(posedge xtal1_in) ;
      end
    endtask

    task transmit_interrupt;
      begin
        enable_interrupt(8'h02);
      end
    endtask 

    task data_overrun_interrupt;
      begin
        enable_interrupt(8'h08);
      end
    endtask 

    task error_passive_interrupt;
      begin
        //reset mode 
        mode_set(`CAN_MODE_RESET);
        write_register(8'h0D,8'h01);
        enable_interrupt(8'h20);
        write_register(8'h0E,8'h7F);
        //operator mode
        mode_set(`CAN_MODE_OPERATOR);
        //
        //set bus free
        repeat(2*BRP)@(posedge xtal1_in) ;
        repeat(11)receive_bit(1);      //set bus free
        repeat(10*BRP)@(posedge xtal1_in); 
        hard_synchronization();
        receive_error_sff_data();
        repeat(10*BRP)@(posedge xtal1_in);
      
         wait(nint == 0)$display("Generate error interrupt");
         read_register(8'h02);
         wait(rdata[6] == 1)$display("Error Status: ES = %b",rdata[6]);
         read_register(8'h03);
         wait(rdata[5] == 1)$display("Error Passive Interrupt: EPI = %b",rdata[5]);
         read_register(8'h03);
         wait(rdata[5] == 0)$display("Error Passive Interrupt clear: EPI = %b",rdata[5]);
       
      end
    endtask 

    task error_warning_interrupt;
      begin
        $display("=========error_warning_interrupt start==========>>>>");
        //reset mode
        mode_set(`CAN_MODE_RESET);
        write_register(8'h0D,8'h01);// ewlr
        enable_interrupt(8'h04);
        //receive error SFF data
        mode_set(`CAN_MODE_OPERATOR);
        //set bus free
        repeat(2*BRP)@(posedge xtal1_in) ;
        repeat(11)receive_bit(1);      //set bus free
        repeat(10*BRP)@(posedge xtal1_in); 
        hard_synchronization();
        receive_error_sff_data();
        repeat(10*BRP)@(posedge xtal1_in);
       
        wait(nint == 0)$display("Generate error warining interrupt ! nint = %b",nint);
        //read status register
        read_register(8'h02);$display("0: status register SR.6 = %b",rdata[6]);
        read_register(8'h03);$display("1: interrupt register IR.2 = %b",rdata[2]);
        read_register(8'h03);$display("1: interrupt register IR.2 = %b",rdata[2]);
        $display("<<<<=========error_warning_interrupt end==========");
      end
    endtask 

  
    
////////////////////////////////////////////////////////////////////////////////////////
    task enable_interrupt;
        input [7:0] data;
        begin
            @(posedge xtal1_in);
            // $display("write register start");
            #1;
            val = 1'b1;
            rd = 1'b0;
            address = 8'h04;
            wdata = data;
            @(posedge xtal1_in);
            #1;
            val = 1'b0;
            address = 8'hz;
            wdata = 8'hz;
            // $display("write register end");
        end
    endtask 
  
////////////////////////////////////////////////////////////////////////////////////////    
  
    task mode_set;
        input [7:0] mode;
        begin
            write_register(8'h00,mode);
            repeat(2*BRP)@(posedge xtal1);
        end
    endtask
    
    task filter_set;
        begin
              write_register(8'h10,`ACR0);     //mod.0 = 1 reset mode , ACR 0--3
              write_register(8'h11,`ACR1);
              write_register(8'h12,`ACR2);
              write_register(8'h13,`ACR3);
              write_register(8'h14,`AMR0);      //AMR 0--3
              write_register(8'h15,`AMR1);
              write_register(8'h16,`AMR2);
              write_register(8'h17,`AMR3);
        end
    endtask
  
    task btr_set;
        begin
             write_register(8'h06,`BTR0);     // mod.0 = 1 reset mode , set bus timing patameter
             write_register(8'h07,`BTR1);  
        end
    endtask


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
   
   task receive_error_sff_data;
        begin
              $display("receive Error SFF data ===>");
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
              receive_bit(1);  // DLC  // error
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
              $display("<====receive Error SFF data");
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
