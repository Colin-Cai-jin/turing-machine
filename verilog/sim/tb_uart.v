`timescale 1ns / 1ns
module tb_uart_all;
tb_uart U[11:0]();
defparam U[0].IS_PARITY = 1'b0;
defparam U[0].PARITY_ODD = 1'b0;
defparam U[0].DATA_BITS = 2'd0;
defparam U[1].IS_PARITY = 1'b0;
defparam U[1].PARITY_ODD = 1'b0;
defparam U[1].DATA_BITS = 2'd1;
defparam U[2].IS_PARITY = 1'b0;
defparam U[2].PARITY_ODD = 1'b0;
defparam U[2].DATA_BITS = 2'd2;
defparam U[3].IS_PARITY = 1'b0;
defparam U[3].PARITY_ODD = 1'b0;
defparam U[3].DATA_BITS = 2'd3;
defparam U[4].IS_PARITY = 1'b1;
defparam U[4].PARITY_ODD = 1'b0;
defparam U[4].DATA_BITS = 2'd0;
defparam U[5].IS_PARITY = 1'b1;
defparam U[5].PARITY_ODD = 1'b0;
defparam U[5].DATA_BITS = 2'd1;
defparam U[6].IS_PARITY = 1'b1;
defparam U[6].PARITY_ODD = 1'b0;
defparam U[6].DATA_BITS = 2'd2;
defparam U[7].IS_PARITY = 1'b1;
defparam U[7].PARITY_ODD = 1'b0;
defparam U[7].DATA_BITS = 2'd3;
defparam U[8].IS_PARITY = 1'b1;
defparam U[8].PARITY_ODD = 1'b1;
defparam U[8].DATA_BITS = 2'd0;
defparam U[9].IS_PARITY = 1'b1;
defparam U[9].PARITY_ODD = 1'b1;
defparam U[9].DATA_BITS = 2'd1;
defparam U[10].IS_PARITY = 1'b1;
defparam U[10].PARITY_ODD = 1'b1;
defparam U[10].DATA_BITS = 2'd2;
defparam U[11].IS_PARITY = 1'b1;
defparam U[11].PARITY_ODD = 1'b1;
defparam U[11].DATA_BITS = 2'd3;
endmodule



module tb_uart;

parameter CLK_REQ = 50_000_000;
parameter BAUD_RATE = 115200;
parameter UART_BIT_WIDTH = CLK_REQ / BAUD_RATE;
parameter SAMPLE_TIMES_A_BIT = 5;
parameter SAMPLE_WIDTH = UART_BIT_WIDTH / SAMPLE_TIMES_A_BIT;

parameter IS_PARITY = 1'b1;
parameter PARITY_ODD = 1'b1;
parameter DATA_BITS = 2'd3;

parameter SEED = 307456789;

reg nRst, clk;
wire clk2;
reg en_snd;
reg [7:0] d_snd;
wire can_snd;
wire en_rcv;
wire [7:0]d_rcv;
wire parity_valid;
wire s;

initial
begin
	nRst = 1;
	#5;
	nRst = 0;
	#1;
	nRst = 1;
end

integer seed;

initial
begin
	en_snd = 0;
	d_snd = 0;
	#40;
	seed = SEED;
	forever
	begin
	#4;
	seed = $random(seed);
	d_snd = seed % 256;
	en_snd = 1;
	#20;
	en_snd = 0;
	@(posedge clk);
	@(posedge clk);
	while(!can_snd)
		@(posedge clk);
	end
end

initial
begin
clk = 0;
forever
begin
	#10;
	clk = !clk;
end
end

assign #10 clk2 = clk;

uart_snd 
#(
	.BIT_WIDTH_BITS($clog2(UART_BIT_WIDTH))
)
U1
(
	.nRst(nRst),
	.clk(clk),

	.bit_width(UART_BIT_WIDTH - 1),
	.en_parity(IS_PARITY),
	.odd_parity(PARITY_ODD),
	.data_bits(DATA_BITS),

	.en(en_snd),
	.data(d_snd),

	.TXD(s),
	.can_snd(can_snd)
);

uart_rcv
#(
	.SAMPLE_WIDTH_BITS($clog2(SAMPLE_WIDTH)),
	.SAMPLE_BITS(SAMPLE_TIMES_A_BIT)
)
U2
(
	.nRst(nRst),
	.clk(clk2),

	.sample_width(SAMPLE_WIDTH - 1), 
	.en_parity(IS_PARITY),
	.odd_parity(PARITY_ODD),
	.data_bits(DATA_BITS),
	.en(en_rcv),
	.data(d_rcv),
	.parity_valid(parity_valid),
	.RXD(s)
);

reg [7:0]catch_data;


wire [7:0]mask = (DATA_BITS == 2'd0) ? 8'hff :
                    ((DATA_BITS == 2'd1) ? 8'h1f :
                    ((DATA_BITS == 2'd2) ? 8'h3f :
                     8'h7d));

integer seq = 0;
integer seq2 = 0;
always@(posedge clk)
	if (en_snd)
		begin
		seq = seq + 1;
		$display("(seq=%d)SEND %b", seq, d_snd);
		catch_data = d_snd;
		end
always@(posedge clk2)
	if (en_rcv)
		begin
		seq2 = seq2 + 1;
		$display("(seq=%d)RECV %b parity(%b)", seq2,  d_rcv, parity_valid);
		if ((d_rcv & mask) != (catch_data & mask) || parity_valid == 1'b0)
			begin
			$display("WRONG!");
			$stop;
			end
		end

endmodule

