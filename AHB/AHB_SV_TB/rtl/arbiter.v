module arbiter (
    input hclk,    // Clock
    input hrst_n,  // Asynchronous reset active low

    input hlockx,

    input hready,
    input ho,
    input [15:0] grant,

    output reg [15:0] hgrantx,
    output reg [2:0] hmaster,
    output reg hmastlock
    
);

always @(posedge hclk or negedge hrst_n) begin 
    if(~hrst_n) begin
        hgrantx <= 'h0;
        hmaster <= 'h0;
        hmastlock <= 'h0;
    end 
end

always @(hlockx or ho or grant or hready) begin 
    if(hlockx) begin
        hmastlock <= 1'b1;
    end
    else begin
        hmastlock <= 1'b0;
    end

    if(hready & ho ) begin
        hgrantx <= grant;

        if(grant[0]) begin
            hmaster <= 3'b000;
        end
        else if(grant[1]) begin
            hmaster <= 3'b001;
        end
        else if(grant[2]) begin
            hmaster <= 3'b010;
        end
        else if(grant[3]) begin
            hmaster <= 3'b011;
        end
        else if(grant[4]) begin
            hmaster <= 3'b100;
        end
        else begin
            hmaster <= 3'h000;
        end


    end
end





endmodule