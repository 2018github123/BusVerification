// *********************************
// Project Name : *
// Target Device: * can_sys_test
// Tool version : *
// Module name  : 
// Function     :
// Attention    : *
// Version History : *
//**********************************
// Engineer     : 
// Data         : 2019-3-13
// Modification  :
//**********************************
// All rights reserved
//
// *********************************
//====

//=========== hardware reset ============

//  MOD register

`define MOD_R  		8'h01

//clkout register

`define CDR_R    	8'h00

//output mode : clock output

`define OCR_R    	8'h00

//receive interrupt enable

`define RIE_R   	8'h00


//===========BUS TIMING REGISTER==========

`define CAN_TIMING0_BRP   6'd4
`define CAN_TIMING0_SJW   2'd1
`define CAN_TIMING1_TSEG1 4'd12
`define CAN_TIMING1_TSEG2 3'd1
`define CAN_TIMING1_SAM   1'd0

//==========SYSTEM CLK====================

`define XTAL1_HALF_PERIODE  25

//==========simulation time ==============

`define CAN_SIMU_TIME   50000000    

//===========MODE==================

`define CAN_MODE_RESET      8'h01
`define CAN_MODE_OPERATOR   8'h00

//=======TRANSMIT FRAME=======

`define EFF  1'b1
`define SFF  1'b0

//=======ACR0-3==============
`define  ACR0  8'h02
`define  ACR1  8'h80
`define  ACR2  8'h02
`define  ACR3  8'h81
//=======AMR0-3==============
`define  AMR0  8'h00
`define  AMR1  8'h0F
`define  AMR2  8'h00
`define  AMR3  8'h0F



























