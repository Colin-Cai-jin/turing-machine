`timescale 1ns / 1ns
module threshold_counter
#(
	parameter WIDTH = 16
)
(
	nRst,
	clk,

	en,
	max,
	reach_max,
	is_zero,
	cnt
);
input nRst, clk;
input en;
input [WIDTH-1:0]max;
output reach_max;
output is_zero;
output [WIDTH-1:0]cnt;
reg [WIDTH-1:0]cnt;

assign reach_max = cnt >= max;
assign is_zero = cnt == {WIDTH {1'b0}};
always@(posedge clk or negedge nRst)
if (!nRst)
	cnt <= {WIDTH {1'b0}};
else if(en & !reach_max)
	cnt <= cnt + 1'b1;
else
	cnt <= {WIDTH {1'b0}};
endmodule
