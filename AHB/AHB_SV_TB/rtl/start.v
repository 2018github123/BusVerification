// arbiter start module : generator grant signal

module start (
    input hclk,    // Clock
    input hrst_n,  // Asynchronous reset active low
    // input hready, // slave is ready
    input [15:0]  hbusreqx,
    input [15:0]  hlockx,
    input [15:0]  hsplitx,
    //input [1:0]  htrans, // type of bus transfer
    input [1:0]  hresp, // response from slave
    input        prio,
    output reg [15:0] grant
);

parameter   OKAY = 2'b00;
parameter   ERROR = 2'b01;
parameter   RETRY = 2'b10;
parameter   SPLIT = 2'b11;

reg [15:0] busreq_q;
reg [15:0] split_q;
wire [15:0] busreq_shield;
wire [15:0] busreq_final;

always @(posedge hclk or negedge hrst_n) begin
    if(~hrst_n) begin
        /* code */
        busreq_q <= 'h0;
        split_q <= 'h0;
    end
    else begin
        busreq_q <= hbusreqx;
        split_q <= hsplitx;

    end
end

assign busreq_final = (split_q != 0)?split_q:busreq_q;

// when hlockx = 1, grant = old grand

always @(hlockx or hresp or prio) begin
    if(hresp == OKAY && hlockx == 0) begin
        if(busreq_final & prio[24:20]) begin
            grant[4:0] = prio[24:20];
        end
        else if(busreq_final & prio[19:15]) begin
            grant[4:0] = prio[19:15];
        end
        else if(busreq_final & prio[14:10]) begin
            grant[4:0] = prio[14:10];
        end
        else if(busreq_final & prio[9:5]) begin
            grant[4:0] = prio[9:5];
        end
        else if(busreq_final & prio[4:0]) begin
            grant[4:0] = prio[4:0];
        end
    end
end

endmodule