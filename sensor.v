module sensor(CLOCK_50, GPIO_0, HEX0, LEDR);
input CLOCK_50;
inout [35:0] GPIO_0;
output [6:0] HEX0;
output [17:0] LEDR;

wire [20:0] sensor_output;

usensor sensor_hex0(.distance(sensor_output),
                    .trig(GPIO_0[0]),
                    .echo(GPIO_0[1]),
                    .clock(CLOCK_50));

hex_display display_hex0(.IN(sensor_output[3:0]),
                          .OUT(HEX0));

assign LEDR[17:0] = sensor_output[17:0];								  
endmodule

module usensor(distance, trig, echo, clock);
  input clock, echo;
  output reg [20:0] distance;
  output reg trig;

  reg [25:0] master_timer;
  reg [25:0] trig_timer;
  reg [25:0] echo_timer;
  reg echo_sense;

  localparam  TRIG_THRESHOLD = 14'b10011100010000,
              MASTER_THRESHOLD = 26'b10111110101111000010000000;


  always @(posedge clock)
  begin
    if (master_timer == MASTER_THRESHOLD)
        master_timer <= 0;
    else if (trig_timer == TRIG_THRESHOLD || echo_sense)
      begin
        trig <= 0;
        echo_sense <= 1;
        if (echo)
			 begin
          echo_timer <= echo_timer + 1;
			 distance <= echo_timer;
			 end
        else
          begin
            echo_timer <= 0;
            trig_timer <= 0;
            echo_sense <= 0;
          end
      end
    else
	 begin
      trig <= 1;
      trig_timer <= trig_timer + 1;
      master_timer <= master_timer + 1;
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