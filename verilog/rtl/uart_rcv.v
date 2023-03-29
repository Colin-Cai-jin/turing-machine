`timescale 1ns / 1ns
module uart_rcv
#(
	parameter SAMPLE_WIDTH_BITS = 15,
	parameter SAMPLE_BITS = 5
)
(
	nRst,
	clk,

	sample_width, //sample_width =  sample width - 1
	en_parity,
	odd_parity,
	data_bits, //5bits =>1, 6bits=>2, 7bits=>3, 8bits=>0

	en,
	data,
	parity_valid,

	RXD
);
input nRst, clk;
input [SAMPLE_WIDTH_BITS-1:0]sample_width;
input en_parity;
input odd_parity;
input [1:0]data_bits;
output en;
output [7:0]data;
output parity_valid;
input RXD;

wire en_sample, set_data_bit;
threshold_counter #(.WIDTH(SAMPLE_WIDTH_BITS)) U1
(
	.nRst(nRst),
	.clk(clk),
	.en(1'b1),
	.max(sample_width),
	.reach_max(set_data_bit),
	.is_zero(en_sample)
);

localparam SUM_BITS = $clog2(SAMPLE_BITS + 1);
localparam JUDGE_THRESHOLD = SAMPLE_BITS / 2;
localparam START_WAIT = JUDGE_THRESHOLD;
localparam START_WAIT_BITS = START_WAIT > 1 ? $clog2(START_WAIT) : 1;

reg [SAMPLE_BITS-1:0]samples;
reg [SUM_BITS-1:0]sum;
wire logic_level = sum > JUDGE_THRESHOLD;

integer i;
always@(*)
begin
	sum = {{(SUM_BITS-1){1'b0}}, samples[0]};
	for (i = 1;i < SAMPLE_BITS; i = i + 1)
	begin : sum_step
		sum = sum + {{(SUM_BITS-1){1'b0}}, samples[i]};
	end
end

always@(posedge clk or negedge nRst)
if (!nRst)
	samples <= {SAMPLE_BITS {1'b1}};
else if (en_sample)
	samples <= {RXD, samples[SAMPLE_BITS-1:1]};

localparam IDLE = 0,
	CHOOSE_START = 1,
	DATA = 2,
	PARITY = 3,
	SEND_RESULT = 4,
	STOP = 5;

reg [SUM_BITS-1:0] count_a_bit;
wire new_bit_moment = (count_a_bit == SAMPLE_BITS-1);
reg [2:0] index;
reg [START_WAIT_BITS-1:0] start_wait_cnt;
reg parity;
reg en;
reg [7:0] data;
reg parity_valid;
reg [2:0] cs, ns;

always@(posedge clk or negedge nRst)
if (!nRst)
	cs <= IDLE;
else
	cs <= ns;

always@(posedge clk or negedge nRst)
if (!nRst)
begin
	count_a_bit <= {SUM_BITS {1'b0}};
	index <= 3'd0;
	start_wait_cnt <= {START_WAIT_BITS {1'b0}};
	parity <= 1'b0;
	en <= 1'b0;
	data <= 8'd0;
	parity_valid <= 1'b1;
end
else
	case (cs)
		CHOOSE_START:
		begin
			count_a_bit <= {SUM_BITS {1'b0}};
			index <= 3'd0;
			if (en_sample)
				start_wait_cnt <= start_wait_cnt + 1'b1;
			parity <= odd_parity;
			en <= 1'b0;
			data <= 8'd0;
			parity_valid <= 1'b1;
		end
		DATA:
		begin
			if (set_data_bit)
			begin
				if (new_bit_moment)
				begin
					count_a_bit <= {SUM_BITS {1'b0}};
					index <= index + 1'b1;
					//$display("data[%d]<=%d", index, logic_level);
					data[index] <= logic_level;
					parity <= parity ^ logic_level;
				end
				else
					count_a_bit <= count_a_bit + 1'b1;
			end
			start_wait_cnt <= {START_WAIT_BITS {1'b0}};
			en <= 1'b0;
			parity_valid <= 1'b1;
		end
		PARITY:
		begin
			index <= 3'd0;
			start_wait_cnt <= {START_WAIT_BITS {1'b0}};
			parity <= 1'b0;
			en <= 1'b0;
			if (en_sample)
			begin
				if (new_bit_moment)
				begin
					count_a_bit <= {SUM_BITS {1'b0}};
					parity_valid <= (logic_level == parity);
				end
				else
					count_a_bit <= count_a_bit + 1'b1;
			end
		end
		SEND_RESULT:
		begin
			index <= 3'd0;
			start_wait_cnt <= {START_WAIT_BITS {1'b0}};
			parity <= 1'b0;
			en <= 1'b1;
			if(en_parity)
				count_a_bit <= count_a_bit + 1'b1;//??
		end
		STOP:
		begin
			index <= 3'd0;
			start_wait_cnt <= {START_WAIT_BITS {1'b0}};
			parity <= 1'b0;
			en <= 1'b0;
			if (en_sample)
			begin
				if (new_bit_moment)
				begin
					count_a_bit <= {SUM_BITS {1'b0}};
				end
				else
					count_a_bit <= count_a_bit + 1'b1;
			end
		end
		default: //IDLE
		begin
			count_a_bit <= {SUM_BITS {1'b0}};
			index <= 3'd0;
			start_wait_cnt <= {START_WAIT_BITS {1'b0}};
			parity <= 1'b0;
			en <= 1'b0;
			data <= 8'd0;
			parity_valid <= 1'b1;
		end
	endcase

always@(*)
	case (cs)
		IDLE:
			ns = logic_level ? IDLE : CHOOSE_START;
		CHOOSE_START:
			ns = (en_sample & start_wait_cnt >= (START_WAIT - 1)) ? DATA : CHOOSE_START;
		DATA:
			if (new_bit_moment & set_data_bit & index == {data_bits != 2'd0, data_bits} - 3'd1)
				if (en_parity)
					ns = PARITY;
				else
					ns = SEND_RESULT;
			else
				ns = DATA;
		PARITY:
			if (new_bit_moment & set_data_bit)
				ns = SEND_RESULT;
			else
				ns = PARITY;
		SEND_RESULT:
			ns = STOP;
		STOP:
			if (new_bit_moment & set_data_bit)
				ns = IDLE;
			else
				ns = STOP;
		default:
			ns = IDLE;
	endcase

endmodule
