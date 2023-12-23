module FFT_f1 (input [31:0] A, input [31:0] B, output [31:0] C);

wire SignA = A[31];
wire SignB = B[31];
wire [7:0]ExpA = A[30:23];
wire [7:0]ExpB = B[30:23];
wire [22:0]ManA = A[22:0];
wire [22:0]ManB = B[22:0];
wire [47:0]ManAD = {24'd0, |ExpA, ManA};
wire [47:0]ManBD = {24'd0, |ExpB, ManB};
wire [47:0]ManCD;
assign ManCD = ManAD * ManBD;
wire [7:0]ExpCD;
wire [24:0] ManF = ManCD[47:23];
wire [7:0] ShMan;
wire [7:0] ExpCh;
wire [7:0] SME;
Decoder Decoder ( .X(ManF), .ShMan(ShMan), .ExpCh(ExpCh));
AdderExp  AdderExp  ( .ExpA(ExpA), .ExpB(ExpB), .ShMan(ShMan), .ExpCD(ExpCD), .SME(SME));
wire L;
assign L = (ShMan > ExpCD)&(~(ExpCD == 8'd1));
wire [7:0]ExpC;
assign ExpC = L? 8'd0 : (ExpCD - ExpCh);
wire [47:0] ShManC;
assign ShManC = L? ((ManCD >> (ExpCD+SME)) << {6'd0, ~(|ExpCD), 1'd0} ):(ManCD << ShMan);
wire [22:0] ManC;
Rounding  #( .N(48), .P(23)) Rounding ( .A(ShManC), .B(ManC));
wire SignC;
assign SignC = SignA ^ SignB; 
assign C = {SignC, ExpC, ManC};

endmodule

module Decoder (input [24:0] X, output reg [7:0] ShMan, output reg [7:0] ExpCh);

always @(*) begin
    casex (X)
        25'b1xxxxxxxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd1; ExpCh = 8'd0; end
        25'b01xxxxxxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd2; ExpCh = 8'd0; end 
        25'b001xxxxxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd3; ExpCh = 8'd1; end 
        25'b0001xxxxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd4; ExpCh = 8'd2; end 
        25'b00001xxxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd5; ExpCh = 8'd3; end 
        25'b000001xxxxxxxxxxxxxxxxxxx: begin ShMan = 8'd6; ExpCh = 8'd4; end 
        25'b0000001xxxxxxxxxxxxxxxxxx: begin ShMan = 8'd7; ExpCh = 8'd5; end 
        25'b00000001xxxxxxxxxxxxxxxxx: begin ShMan = 8'd8; ExpCh = 8'd6; end 
        25'b000000001xxxxxxxxxxxxxxxx: begin ShMan = 8'd9; ExpCh = 8'd7; end 
        25'b0000000001xxxxxxxxxxxxxxx: begin ShMan = 8'd10; ExpCh = 8'd8; end 
        25'b00000000001xxxxxxxxxxxxxx: begin ShMan = 8'd11; ExpCh = 8'd9; end 
        25'b000000000001xxxxxxxxxxxxx: begin ShMan = 8'd12; ExpCh = 8'd10; end 
        25'b0000000000001xxxxxxxxxxxx: begin ShMan = 8'd13; ExpCh = 8'd11; end 
        25'b00000000000001xxxxxxxxxxx: begin ShMan = 8'd14; ExpCh = 8'd12; end 
        25'b000000000000001xxxxxxxxxx: begin ShMan = 8'd15; ExpCh = 8'd13; end 
        25'b0000000000000001xxxxxxxxx: begin ShMan = 8'd16; ExpCh = 8'd14; end 
        25'b00000000000000001xxxxxxxx: begin ShMan = 8'd17; ExpCh = 8'd15; end 
        25'b000000000000000001xxxxxxx: begin ShMan = 8'd18; ExpCh = 8'd16; end 
        25'b0000000000000000001xxxxxx: begin ShMan = 8'd19; ExpCh = 8'd17; end
        25'b00000000000000000001xxxxx: begin ShMan = 8'd20; ExpCh = 8'd18; end 
        25'b000000000000000000001xxxx: begin ShMan = 8'd21; ExpCh = 8'd19; end 
        25'b0000000000000000000001xxx: begin ShMan = 8'd22; ExpCh = 8'd20; end 
        25'b00000000000000000000001xx: begin ShMan = 8'd23; ExpCh = 8'd21; end 
        25'b000000000000000000000001x: begin ShMan = 8'd24; ExpCh = 8'd22; end 
        25'b0000000000000000000000001: begin ShMan = 8'd25; ExpCh = 8'd23; end 
        25'b0000000000000000000000000: begin ShMan = 8'd26; ExpCh = 8'd24; end  
        default: begin ShMan = 8'd0;  ExpCh = 8'd0; end  
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

module AdderExp  (input [7:0] ExpA, input [7:0] ExpB, input [7:0] ShMan, output [7:0] ExpCD, output reg [7:0] SME);

wire [9:0] Adder;
assign Adder = { 8'd0, ~(|{ShMan [7:1], ~ShMan [0]})};
wire X;
wire [9:0]ExpAD;
assign X = ExpA < 8'b01111111;
assign ExpAD = X? -(10'b0001111111-{1'b0, 1'b0, ExpA}-{9'd0, ~(|ExpA)}):({1'b0, 1'b0, ExpA}-10'b0001111111);
wire Y;
wire [9:0]ExpBD;
assign Y = ExpB < 8'b01111111;
assign ExpBD = Y? -(10'b0001111111-{1'b0, 1'b0, ExpB}-{9'd0, ~(|ExpB)}):({1'b0, 1'b0, ExpB}-10'b0001111111);
wire [9:0]ExpCDF;
assign ExpCDF = ExpAD + ExpBD + Adder;
assign SignCDF = ExpCDF[9];
wire [9:0] ModExpCDF;
assign ModExpCDF = SignCDF? -ExpCDF:ExpCDF;
wire [9:0]ExpCDP;
assign ExpCDP = ExpCDF + 10'b0001111111;
wire [7:0]ExpCDR = ExpCDP[7:0];
wire M;
assign M = ModExpCDF  >= 10'd127;
wire [1:0] Z = {SignCDF, M};
wire [9:0] ShManExp;
wire N;
assign N = (|ExpA)&(|ExpB); 
assign ShManExp = ModExpCDF - 10'd126 + {9'd0, N} ;

reg [7:0] ExpCDM;

always @(*) begin

    case (Z)
        2'b01: begin
          ExpCDM = 8'b11111111; SME = 8'd0;
        end
        2'b11: begin
          ExpCDM = 8'b00000000; SME = ShManExp [7:0];
        end
        default: begin
          ExpCDM = ExpCDR; SME = 8'd0;
        end 
    endcase
    
end

assign ExpCD = ExpCDM;
endmodule