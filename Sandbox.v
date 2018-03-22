module Sandbox(SW, GPIO, CLOCK_50, HEX0, LEDR);
input CLOCK_50;
input [17:0] SW;
output [17:0] LEDR;
inout [35:0] GPIO;
output [6:0] HEX0;


wire [25:0] out;
assign GPIO[2] = SW[0];
assign LEDR[0] = SW[0];

sensor sns(.trig(GPIO[0]), .echo(GPIO[1]), .clk(CLOCK_50), .out(out));

hex_display hex0(.IN(out), .OUT(HEX0));
endmodule


module counter(out, enable, clear_b, clock);
  input clock, enable, clear_b;
  output reg[25:0] out;

  always @(posedge clock)
  begin
    if (clear_b == 1'b0)
      out <= 26'd0;
    else if (out == 26'b11111111111111111111111111)
      out <= 26'b0;
    else if (enable == 1'b1)
      out <= out + 1;
  end
endmodule

module sensor(trig, echo, clk, out);
	input clk, echo;
	output reg trig;
	output reg out;

	wire trig_time = 14'b10011100010000;


	wire [25:0] counter;
	reg [25:0] echo_counter;
	reg [13:0] trig_counter;
	reg clear_signal = 1;
	reg count_signal = 1;

	counter cntr(.out(counter), .enable(count_signal), .clear_b(clear_signal), .clock(clk));

	always@(posedge clk)
		begin
			if (counter < trig_time)
				trig <= 1;
			else if (counter >= trig_counter)
				begin
					trig <= 0;
				end
				
			if (echo)
				begin
					echo_counter <= counter;
					count_signal <= 0;
					out <= echo_counter - trig_time;
				end
		end
endmodule
	
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule
