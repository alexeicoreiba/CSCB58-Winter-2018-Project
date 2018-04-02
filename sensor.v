module sensor(SW, CLOCK_25, CLOCK_50, GPIO_0, HEX0, HEX1, HEX2, LEDR);
input CLOCK_25, CLOCK_50;
inout [35:0] GPIO_0;
output [6:0] HEX0, HEX1, HEX2;
output [17:0] LEDR;
input [17:0] SW; 

wire [20:0] sensor_output;
wire [3:0] hundreds, tens, ones;

music buzzbuzz(.speaker(GPIO_0[3]), 
					 .clk(CLOCK_25),
					 .distance(sensor_output[7:0])
);


usensor sensor_hex0(.distance(sensor_output),
                    .trig(GPIO_0[0]),
                    .echo(GPIO_0[1]),
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
					temp_distance <= (echo_timer / 2900);
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

module buzzer(speaker, clk, distance);
	input clk; 
	input [7:0] distance; 
	output speaker; 
	reg clkdivider = 125000000/distance * 2056;

	reg [14:0] counter;
	always @(posedge clk) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;

	reg speaker;
	always @(posedge clk) if(counter==0) speaker <= ~speaker;
	
endmodule


// Source is http://www.fpga4fun.com/MusicBox4.html
module music(
	input clk,
	output reg speaker,
	input [7:0] distance
);



wire [7:0] fullnote;
music_ROM get_fullnote(.clk(clk), .address(distance[7:0]), .note(fullnote));

wire [2:0] octave;
wire [3:0] note;
divide_by12 get_octave_and_note(.numerator(fullnote[5:0]), .quotient(octave), .remainder(note));

reg [8:0] clkdivider;
always @*
case(note)
	 0: clkdivider = 9'd511;//A
	 1: clkdivider = 9'd482;// A#/Bb
	 2: clkdivider = 9'd455;//B
	 3: clkdivider = 9'd430;//C
	 4: clkdivider = 9'd405;// C#/Db
	 5: clkdivider = 9'd383;//D
	 6: clkdivider = 9'd361;// D#/Eb
	 7: clkdivider = 9'd341;//E
	 8: clkdivider = 9'd322;//F
	 9: clkdivider = 9'd303;// F#/Gb
	10: clkdivider = 9'd286;//G
	11: clkdivider = 9'd270;// G#/Ab
	default: clkdivider = 9'd0;
endcase

reg [8:0] counter_note;
reg [7:0] counter_octave;
always @(posedge clk) counter_note <= counter_note==0 ? clkdivider : counter_note-9'd1;
always @(posedge clk) if(counter_note==0) counter_octave <= counter_octave==0 ? 8'd255 >> octave : counter_octave-8'd1;
always @(posedge clk) if(counter_note==0 && counter_octave==0 && fullnote!=0 && distance[7:0]!=0) speaker <= ~speaker;
endmodule


/////////////////////////////////////////////////////
module divide_by12(
	input [5:0] numerator,  // value to be divided by 12
	output reg [2:0] quotient, 
	output [3:0] remainder
);

reg [1:0] remainder3to2;
always @(numerator[5:2])
case(numerator[5:2])
	 0: begin quotient=0; remainder3to2=0; end
	 1: begin quotient=0; remainder3to2=1; end
	 2: begin quotient=0; remainder3to2=2; end
	 3: begin quotient=1; remainder3to2=0; end
	 4: begin quotient=1; remainder3to2=1; end
	 5: begin quotient=1; remainder3to2=2; end
	 6: begin quotient=2; remainder3to2=0; end
	 7: begin quotient=2; remainder3to2=1; end
	 8: begin quotient=2; remainder3to2=2; end
	 9: begin quotient=3; remainder3to2=0; end
	10: begin quotient=3; remainder3to2=1; end
	11: begin quotient=3; remainder3to2=2; end
	12: begin quotient=4; remainder3to2=0; end
	13: begin quotient=4; remainder3to2=1; end
	14: begin quotient=4; remainder3to2=2; end
	15: begin quotient=5; remainder3to2=0; end
endcase

assign remainder[1:0] = numerator[1:0];  // the first 2 bits are copied through
assign remainder[3:2] = remainder3to2;  // and the last 2 bits come from the case statement
endmodule
/////////////////////////////////////////////////////


module music_ROM(
	input clk,
	input [7:0] address,
	output reg [7:0] note
);

always @(posedge clk)
case(address)
	  0: note<= 8'd10;
	  1: note<= 8'd10;
	  2: note<= 8'd10;
	  3: note<= 8'd10;
	  4: note<= 8'd10;
	  5: note<= 8'd10;
	  6: note<= 8'd11;
	  7: note<= 8'd11;
	  8: note<= 8'd11;
	  9: note<= 8'd11;
	 10: note<= 8'd12;
	 11: note<= 8'd12;
	 12: note<= 8'd12;
	 13: note<= 8'd12;
	 14: note<= 8'd12;
	 15: note<= 8'd12;
	 16: note<= 8'd13;
	 17: note<= 8'd13;
	 18: note<= 8'd13;
	 19: note<= 8'd13;
	 20: note<= 8'd13;
	 21: note<= 8'd14;
	 22: note<= 8'd14;
	 23: note<= 8'd14;
	 24: note<= 8'd14;
	 25: note<= 8'd14;
	 26: note<= 8'd15;
	 27: note<= 8'd15;
	 28: note<= 8'd15;
	 29: note<= 8'd15;
	 30: note<= 8'd15;
	 31: note<= 8'd16;
	 32: note<= 8'd16;
	 33: note<= 8'd16;
	 34: note<= 8'd16;
	 35: note<= 8'd16;
	 36: note<= 8'd17;
	 37: note<= 8'd17;
	 38: note<= 8'd17;
	 39: note<= 8'd17;
	 40: note<= 8'd17;
	 41: note<= 8'd18;
	 42: note<= 8'd18;
	 43: note<= 8'd18;
	 44: note<= 8'd18;
	 45: note<= 8'd18;
	 46: note<= 8'd19;
	 47: note<= 8'd19;
	 48: note<= 8'd19;
	 49: note<= 8'd19;
	 50: note<= 8'd19;
	 51: note<= 8'd20;
	 52: note<= 8'd20;
	 53: note<= 8'd20;
	 54: note<= 8'd20;
	 55: note<= 8'd20;
	 56: note<= 8'd21;
	 57: note<= 8'd21;
	 58: note<= 8'd21;
	 59: note<= 8'd21;
	 60: note<= 8'd22;
	 61: note<= 8'd22;
	 62: note<= 8'd22;
	 63: note<= 8'd22;
	 64: note<= 8'd22;
	 65: note<= 8'd22;
	 66: note<= 8'd23;
	 67: note<= 8'd23;
	 68: note<= 8'd23;
	 69: note<= 8'd23;
	 70: note<= 8'd34;
	 71: note<= 8'd34;
	 72: note<= 8'd24;
	 73: note<= 8'd24;
	 74: note<= 8'd24;
	 75: note<= 8'd24;
	 76: note<= 8'd25;
	 77: note<= 8'd25;
	 78: note<= 8'd25;
	 79: note<= 8'd25;
	 80: note<= 8'd25;
	 81: note<= 8'd26;
	 82: note<= 8'd26;
	 83: note<= 8'd26;
	 84: note<= 8'd26;
	 85: note<= 8'd26;
	 86: note<= 8'd27;
	 87: note<= 8'd27;
	 88: note<= 8'd27;
	 89: note<= 8'd27;
	 90: note<= 8'd27;
	 91: note<= 8'd28;
	 92: note<= 8'd28;
	 93: note<= 8'd28;
	 94: note<= 8'd28;
	 95: note<= 8'd29;
	 96: note<= 8'd29;
	 97: note<= 8'd29;
	 98: note<= 8'd29;
	 99: note<= 8'd29;
	100: note<= 8'd29;
	101: note<= 8'd30;
	102: note<= 8'd30;
	103: note<= 8'd30;
	104: note<= 8'd30;
	105: note<= 8'd30;
	106: note<= 8'd31;
	107: note<= 8'd31;
	108: note<= 8'd31;
	default: note <= 8'd32;
endcase
endmodule

/////////////////////////////////////////////////////