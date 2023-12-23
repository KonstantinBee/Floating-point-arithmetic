module adder (input [31:0] A, input [31:0] B, output [31:0] C);

wire SignA = A[31];
wire SignB = B[31];
wire [7:0]ExpA = A[30:23];
wire [7:0]ExpB = B[30:23];
wire [22:0]ManA = A[22:0];
wire [22:0]ManB = B[22:0];
wire X;
assign  X = (ExpA > ExpB);
wire [7:0]ExpH;
assign ExpH = X?ExpA:ExpB;
wire [7:0]ExpL;
assign ExpL = ~X?ExpA:ExpB;
wire SignH;
assign SignH = X?SignA:SignB;
wire SignL;
assign SignL = ~X?SignA:SignB;
wire [153:0]ManAD = {1'b0, 1'b0, |ExpA, ManA, 128'b0};
wire [153:0]ManBD = {1'b0, 1'b0, |ExpB, ManB, 128'b0};
wire [153:0]ManH;
assign ManH = X?ManAD:ManBD;
wire [153:0]ManL;
assign ManL = ~X?ManAD:ManBD;
wire [153:0]ManLK;
assign ManLK = ManL >> (ExpH-ExpL-({7'd0, (~|ExpL)&(|ExpH)}));
wire [153:0]ManLKS;
assign ManLKS = SignL?(-ManLK):ManLK;
wire [153:0]ManHS;
assign ManHS = SignH?(-ManH):ManH;
wire [153:0]ManCR;
assign ManCR = ManHS + ManLKS;
wire SignC = ManCR[153];
wire [153:0]ManCS;
assign ManCS = SignC?(-ManCR):ManCR;
wire [152:0]ManCA = ManCS[152:0];
wire [7:0]M;
wire [23:0]ManF = ManCA[152:129];
Decoder Decoder ( .X(ManF), .Y(M));
wire U;
assign U = (ExpH > M);
wire [7:0]S;
assign S = U?(M+1):(ExpH + 8'd2 - ({7'd0, (|ExpH)}));
wire [152:0]ManCD;
assign ManCD = ManCA << S;
wire [7:0]ExpC;
assign ExpC = (U?(ExpH+1-M):8'd0) + ((ExpH == 8'd0)&(M == 8'd1));
wire [22:0]ManC;
Rounding  #( .N(153), .P(23)) Rounding ( .A(ManCD), .B(ManC));
assign C = {SignC, ExpC, ManC};

endmodule

module Decoder (input [23:0] X, output reg [7:0]Y);

always @(*) begin
    casex (X)
        24'b1xxxxxxxxxxxxxxxxxxxxxxx: Y=8'd0;
        24'b01xxxxxxxxxxxxxxxxxxxxxx: Y=8'd1;
        24'b001xxxxxxxxxxxxxxxxxxxxx: Y=8'd2;
        24'b0001xxxxxxxxxxxxxxxxxxxx: Y=8'd3;
        24'b00001xxxxxxxxxxxxxxxxxxx: Y=8'd4;
        24'b000001xxxxxxxxxxxxxxxxxx: Y=8'd5;
        24'b0000001xxxxxxxxxxxxxxxxx: Y=8'd6;
        24'b00000001xxxxxxxxxxxxxxxx: Y=8'd7;
        24'b000000001xxxxxxxxxxxxxxx: Y=8'd8;
        24'b0000000001xxxxxxxxxxxxxx: Y=8'd9;
        24'b00000000001xxxxxxxxxxxxx: Y=8'd10;
        24'b000000000001xxxxxxxxxxxx: Y=8'd11;
        24'b0000000000001xxxxxxxxxxx: Y=8'd12;
        24'b00000000000001xxxxxxxxxx: Y=8'd13;
        24'b000000000000001xxxxxxxxx: Y=8'd14;
        24'b0000000000000001xxxxxxxx: Y=8'd15;
        24'b00000000000000001xxxxxxx: Y=8'd16;
        24'b000000000000000001xxxxxx: Y=8'd17;
        24'b0000000000000000001xxxxx: Y=8'd18;
        24'b00000000000000000001xxxx: Y=8'd19;
        24'b000000000000000000001xxx: Y=8'd20;
        24'b0000000000000000000001xx: Y=8'd21;
        24'b00000000000000000000001x: Y=8'd22;
        24'b000000000000000000000001: Y=8'd23;
        24'b000000000000000000000000: Y=8'd24; 
        default: Y=8'd0; 
    endcase
    
end

endmodule

module Rounding #(parameter N = 8, P = 3) (input [N-1:0]A, output [P-1:0] B);
wire list_bit = A[N-P];
wire round_bit = A[N-P-1];
wire sticky_bit = |A[N-P-2:0];
wire [P-1:0] BI = A[N-1:N-P];
reg R;

wire [2:0] LRS = {list_bit, round_bit, sticky_bit};

always @(*) begin
    case (LRS)
        3'b000: R = 1'b0;
        3'b001: R = 1'b0; 
        3'b010: R = 1'b0; 
        3'b011: R = 1'b1; 
        3'b100: R = 1'b0; 
        3'b101: R = 1'b0; 
        3'b110: R = 1'b1; 
        3'b111: R = 1'b1;  
        default: R = 1'b0;
    endcase    
end

assign B = BI+R;

endmodule