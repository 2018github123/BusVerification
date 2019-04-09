

module prio (
    input clk,    // Clock
    input rst_n,  // Asynchronous reset active low
    input [15:0] hgrantx,
    output reg [24:0] prio
);

parameter S0 = 3'b000;
parameter S1 = 3'b001;
parameter S2 = 3'b010;
parameter S3 = 3'b011;

reg [2:0] state;
reg [2:0] nxt_state;

//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state <= S0;
    end else begin
        state <= nxt_state;
    end
end

always @(state or hgrantx) begin 
    case (state)
        S0:
            if(hgrantx[1]) begin
                nxt_state <= S1;
            end
            else if(hgrantx[2]) begin
                nxt_state <= S2;
            end
            else if(hgrantx[3]) begin
                nxt_state <= S3;
            end
            else begin
                nxt_state <= S0;
            end

        S1:
            if(hgrantx[2]) begin
                nxt_state <= S2;
            end
            else if(hgrantx[3]) begin
                nxt_state <= S3;
            end
            else if(hgrantx[4]) begin
                nxt_state <= S0;
            end
            else begin
                nxt_state <= S1;
            end

        S2:
            if(hgrantx[1]) begin
                nxt_state <= S1;
            end
            else if(hgrantx[3]) begin
                nxt_state <= S3;
            end
            else if(hgrantx[4]) begin
                nxt_state <= S0;
            end
            else begin
                nxt_state <= S2;
            end

        S3:
            if(hgrantx[1]) begin
                nxt_state <= S1;
            end
            else if(hgrantx[2]) begin
                nxt_state <= S2;
            end
            else if(hgrantx[4]) begin
                nxt_state <= S0;
            end
            else begin
                nxt_state <= S3;
            end

        default :state <= S0;
    endcase
end

always @(state) begin
    case (state)
        S0: prio = 25'b00001_00010_00100_01000_10000;
        S1: prio = 25'b00001_00100_01000_10000_00010;
        S2: prio = 25'b00001_01000_10000_00010_00100;
        S3: prio = 25'b00001_10000_00010_00100_01000;
        default : prio = 25'b00001_00010_00100_01000_10000;
    endcase
end

endmodule