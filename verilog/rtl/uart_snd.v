`timescale 1ns / 1ns
module uart_snd
#(
	parameter BIT_WIDTH_BITS = 16
)
(
	nRst,
	clk,

	bit_width, //bit_width =  bit width - 1, must >= 2
	en_parity,
	odd_parity,
	data_bits, //5bits =>1, 6bits=>2, 7bits=>3, 8bits=>0

	en,
	data,

	TXD,
	can_snd
);
input nRst, clk;
input [BIT_WIDTH_BITS-1:0]bit_width;
input en_parity;
input odd_parity;
input [1:0]data_bits;
input en;
input [7:0]data;
output TXD;
output can_snd;

parameter IDLE = 0,
	START_BIT = 1,
	//DATA_LOW_4_BITS = 2,
	DATA_HIGH_BITS = 3,
	PARITY_BIT = 4,
	STOP_BIT = 5;

wire [BIT_WIDTH_BITS-1:0]cnt_bit;
reg [2:0] cs, ns;
reg TXD;
reg [2:0]index;
wire [2:0]index_add1 = index + 1'b1;
reg parity;

wire bit_over;
//assign bit_over = (cnt_bit >= bit_width);
threshold_counter #(.WIDTH(BIT_WIDTH_BITS)) U1
(
	.nRst(nRst),
	.clk(clk),
	.en(cs != IDLE),
	.max(bit_width),
	.reach_max(bit_over),
	.cnt(cnt_bit)
);

reg can_snd;
always@(posedge clk or negedge nRst)
if (!nRst)
	can_snd <= 1'b1;
else
	case (cs)
		IDLE:
			can_snd <= 1'b1;
		STOP_BIT:
			if (cnt_bit < bit_width  - 'b10)
				can_snd <= 1'b0;
			else
				can_snd <= 1'b1;
		default:
			can_snd <= 1'b0;
	endcase	

always@(posedge clk or negedge nRst)
if (!nRst)
	cs <= IDLE;
else
	cs <= ns;

always@(posedge clk or negedge nRst)
if (!nRst)
	begin
	TXD <= 1'b1;
	index <= 3'd0;
	parity <= 1'b0;
	end
else
	case (ns)
		IDLE:
			TXD <= 1'b1;
		START_BIT:
		begin
			TXD <= 1'b0;
			parity <= odd_parity;
			index <= 3'd0;
		end
/*
		DATA_LOW_4_BITS:
		begin
			if (bit_over)
			begin
				parity <= parity ^ data[{1'b0, index}];
				TXD <= data[{1'b0, index}];
			end
			if (cnt_bit == 'b0)
				index <= index_add1;
		end
*/
		DATA_HIGH_BITS:
		begin
			if (bit_over)
			begin
				parity <= parity ^ data[index];
				TXD <= data[index];
			end
			if (cnt_bit == 'b0)
				index <= index_add1;
		end
		PARITY_BIT:
			TXD <= parity; 
		STOP_BIT:
			TXD <= 1'b1;
		default:
			TXD <= 1'b1;

	endcase

always@(*)
case (cs)
IDLE:
	if (en)
		ns = START_BIT;
	else
		ns = IDLE;
START_BIT:
	if (bit_over)
		ns = DATA_HIGH_BITS;//DATA_LOW_4_BITS;
	else
		ns = START_BIT;
/*
DATA_LOW_4_BITS:
	if (bit_over && index == 2'd0)
		ns = DATA_HIGH_BITS;
	else
		ns = DATA_LOW_4_BITS;
*/
DATA_HIGH_BITS:
	if (bit_over && index == {data_bits != 2'b00, data_bits})
		ns = en_parity ? PARITY_BIT : STOP_BIT;
	else
		ns = DATA_HIGH_BITS;
PARITY_BIT:
	if (bit_over)
		ns = STOP_BIT;
	else
		ns = PARITY_BIT;
STOP_BIT:
	if (bit_over)
		ns = en ? START_BIT : IDLE;
	else
		ns = STOP_BIT;
default:
	ns = IDLE;
endcase

endmodule
