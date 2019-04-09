//Project:
//Function: AHB Arbiter
//          
//Author:
//Date:  2019-4-9
//
//Modified:
//
//------------------------------------

module ahb_arbiter (
    //reset and clk
    input hclk,    // Clock
    input hrst_n,  // Asynchronous reset active low
    //arbiter requests and locks
    input [15:0]  hbusreqx,
    input [15:0]  hlockx,
    //address and control
    input [31:0]  haddr,
    input [15:0]  hsplitx,
    input [1:0]   htrans,
    input [2:0]   hburst,
    input [1:0]   hresp,
    input         hready,
    // arbiter grants
    output [15:0] hgrantx,
    output [3:0]  hmaster,
    output        hmastlock
);

reg [24:0] prio;
reg [15:0] grant;
reg        ho;

    // ******  Master Requesting Bus Access  ******
    //         rising of clk and internal priority algorithm to decide which master

    start dut1(.hclk(hclk),
               .hrst_n(hrst_n),
               .hbusreqx(hbusreqx),
               .hlockx(hlockx),
               .hsplitx(hsplitx),
               .hresp(hresp),
               .prio(prio),
               .grant(grant));

    prio dut2(.clk(hclk),
              .rst_n(hrst_n),
              .hgrantx(hgrantx),
              .prio(prio));

    grant dut3(.hclk(hclk),
               .hrst_n(hrst_n),
               .hready(hready),
               .htrans(htrans),
               .hburst(hburst),
               .hresp(hresp),
               .hmastlock(hmastlock),
               .hgrantx(hgrantx),
               .ho(ho));

    arbiter dut4(.hclk(hclk),
                 .hrst_n(hrst_n),
                 .hlockx(hlockx),
                 .hready(hready),
                 .ho(ho),
                 .grant(grant),
                 .hgrantx(hgrantx),
                 .hmaster(hmaster),
                 .hmastlock(hmastlock));
    
endmodule