module sensor(CLOCK_50, GPIO, HEX0, HEX1, HEX2, LEDR);
input CLOCK_50;
inout [35:0] GPIO;
output [6:0] HEX0, HEX1, HEX2;
output [17:0] LEDR;

wire [20:0] sensor_output;
wire [3:0] hundreds, tens, ones;

usensor sensor_hex0(.distance(sensor_output),
                    .trig(GPIO[0]),
                    .echo(GPIO[1]),
                    .clock(CLOCK_50));
						  
						  
assign LEDR[17:0] = sensor_output[17:0];

BCD bcd(
  .binary(sensor_output[7:0]),
  .Hundreds(hundreds),
  .Tens(tens),
  .Ones(ones)
  );

// hex_display display_hex0(.IN(sensor_output[3:0]),
//                           .OUT(HEX0));

hex_display display_hundreds(
  .IN(hundreds),
  .OUT(HEX2)
  );

hex_display display_tens(
  .IN(tens),
  .OUT(HEX1)
  );

hex_display display_ones(
  .IN(ones),
  .OUT(HEX0)
  );

assign LEDR[17:0] = sensor_output[17:0];
endmodule

module usensor(distance, trig, echo, clock);
  input clock, echo;
  output reg [25:0] distance;
  output reg trig;

  reg [25:0] master_timer;
  reg [25:0] trig_timer;
  reg [25:0] echo_timer;
  reg [25:0] echo_shift10;
  reg [25:0] echo_shift12;
  reg [25:0] temp_distance;
  reg echo_sense, echo_high;

  localparam  TRIG_THRESHOLD = 14'b10011100010000,
              MASTER_THRESHOLD = 26'b10111110101111000010000000;


  always @(posedge clock)
  begin
    if (master_timer == MASTER_THRESHOLD)
		begin
        master_timer <= 0;
		  
		  end
    else if (trig_timer == TRIG_THRESHOLD || echo_sense)
      begin
        trig <= 0;
        echo_sense <= 1;
        if (echo)
			    begin
					echo_high <= 1;
					echo_timer <= echo_timer + 1;
					//echo_shift10 <= echo_timer >> 10;
					//echo_shift12 <= echo_timer >> 12;
					temp_distance <= (echo_timer / 2500);
					//distance <= (echo_shift10 - echo_shift12) >> 1;
					//distance <= (echo_timer >> 13) * 3;
			    end
        else
          begin
				distance <= temp_distance;
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

// BINARY TO BCD CONVERSION ALGORITHM
// CODE REFERENCED FROM
// http://www.eng.utah.edu/~nmcdonal/Tutorials/BCDTutorial/BCDConversion.html
module BCD (
  input [7:0] binary,
  output reg [3:0] Hundreds,
  output reg [3:0] Tens,
  output reg [3:0] Ones
  );

  integer i;
  always @(binary)
  begin
    //set 100's, 10's, and 1's to 0
    Hundreds = 4'd0;
    Tens = 4'd0;
    Ones = 4'd0;

    for (i = 7; i >=0; i = i-1)
    begin
      //add 3 to columns >= 5
      if (Hundreds >= 5)
        Hundreds = Hundreds + 3;
      if (Tens >= 5)
        Tens = Tens + 3;
      if (Ones >= 5)
        Ones = Ones + 3;

      //shift left one
      Hundreds = Hundreds << 1;
      Hundreds[0] = Tens[3];
      Tens = Tens << 1;
      Tens[0] = Ones[3];
      Ones = Ones << 1;
      Ones[0] = binary[i];
    end
  end
endmodule
