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
					//////////////////////////////////////////////////////
					// CLOCK_50 -> 50 000 000 clock cycles per second
					// let n = number of cycles
					// speed of sound in air: 340m/s
					// n / 50 000 000 = num of seconds
					// num of seconds * 340m/s = meters
					// meters * 100 = cm ~ distance to object and back
					// So we divide by 2 to get distance to object
					// 1/ 50 000 000 * 340 * 100 / 2 = 0.00034
					// n * 0.00034 = n * 34/100 000 = n / (100 000/34)
					// = 2941
					// To make up for sensor inaccuracy and simple math
					// we round down to 2900
					temp_distance <= (echo_timer / 2900);
					//////////////////////////////////////////////////////
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


// Source is http://www.fpga4fun.com/MusicBox4.htmls
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
	200 :note<=8'd05;
	199 :note<=8'd06;
	198 :note<=8'd06;
	197 :note<=8'd06;
	196 :note<=8'd06;
	195 :note<=8'd06;
	194 :note<=8'd06;
	193 :note<=8'd06;
	192 :note<=8'd07;
	191 :note<=8'd07;
	190 :note<=8'd07;
	189 :note<=8'd07;
	188 :note<=8'd07;
	187 :note<=8'd07;
	186 :note<=8'd07;
	185 :note<=8'd08;
	184 :note<=8'd08;
	183 :note<=8'd08;
	182 :note<=8'd08;
	181 :note<=8'd08;
	180 :note<=8'd08;
	179 :note<=8'd08;
	178 :note<=8'd09;
	177 :note<=8'd09;
	176 :note<=8'd09;
	175 :note<=8'd09;
	174 :note<=8'd09;
	173 :note<=8'd09;
	172 :note<=8'd09;
	171 :note<=8'd10;
	170 :note<=8'd10;
	169 :note<=8'd10;
	168 :note<=8'd10;
	167 :note<=8'd10;
	166 :note<=8'd10;
	165 :note<=8'd10;
	164 :note<=8'd11;
	163 :note<=8'd11;
	162 :note<=8'd11;
	161 :note<=8'd11;
	160 :note<=8'd11;
	159 :note<=8'd11;
	158 :note<=8'd11;
	157 :note<=8'd12;
	156 :note<=8'd12;
	155 :note<=8'd12;
	154 :note<=8'd12;
	153 :note<=8'd12;
	152 :note<=8'd12;
	151 :note<=8'd12;
	150 :note<=8'd13;
	149 :note<=8'd13;
	148 :note<=8'd13;
	147 :note<=8'd13;
	146 :note<=8'd13;
	145 :note<=8'd13;
	144 :note<=8'd13;
	143 :note<=8'd14;
	142 :note<=8'd14;
	141 :note<=8'd14;
	140 :note<=8'd14;
	139 :note<=8'd14;
	138 :note<=8'd14;
	137 :note<=8'd14;
	136 :note<=8'd15;
	135 :note<=8'd15;
	134 :note<=8'd15;
	133 :note<=8'd15;
	132 :note<=8'd15;
	131 :note<=8'd15;
	130 :note<=8'd15;
	129 :note<=8'd16;
	128 :note<=8'd16;
	127 :note<=8'd16;
	126 :note<=8'd16;
	125 :note<=8'd16;
	124 :note<=8'd16;
	123 :note<=8'd16;
	122 :note<=8'd17;
	121 :note<=8'd17;
	120 :note<=8'd17;
	119 :note<=8'd17;
	118 :note<=8'd17;
	117 :note<=8'd17;
	116 :note<=8'd17;
	115 :note<=8'd18;
	114 :note<=8'd18;
	113 :note<=8'd18;
	112 :note<=8'd18;
	111 :note<=8'd18;
	110 :note<=8'd18;
	109 :note<=8'd18;
	108 :note<=8'd19;
	107 :note<=8'd19;
	106 :note<=8'd19;
	105 :note<=8'd19;
	104 :note<=8'd19;
	103 :note<=8'd19;
	102 :note<=8'd19;
	101 :note<=8'd20;
	100 :note<=8'd20;
	99 :note<=8'd20;
	98 :note<=8'd20;
	97 :note<=8'd20;
	96 :note<=8'd20;
	95 :note<=8'd20;
	94 :note<=8'd21;
	93 :note<=8'd21;
	92 :note<=8'd21;
	91 :note<=8'd21;
	90 :note<=8'd21;
	89 :note<=8'd21;
	88 :note<=8'd21;
	87 :note<=8'd22;
	86 :note<=8'd22;
	85 :note<=8'd22;
	84 :note<=8'd22;
	83 :note<=8'd22;
	82 :note<=8'd22;
	81 :note<=8'd22;
	80 :note<=8'd23;
	79 :note<=8'd23;
	78 :note<=8'd23;
	77 :note<=8'd23;
	76 :note<=8'd23;
	75 :note<=8'd23;
	74 :note<=8'd23;
	73 :note<=8'd24;
	72 :note<=8'd24;
	71 :note<=8'd24;
	70 :note<=8'd24;
	69 :note<=8'd24;
	68 :note<=8'd24;
	67 :note<=8'd24;
	66 :note<=8'd25;
	65 :note<=8'd25;
	64 :note<=8'd25;
	63 :note<=8'd25;
	62 :note<=8'd25;
	61 :note<=8'd25;
	60 :note<=8'd25;
	59 :note<=8'd26;
	58 :note<=8'd26;
	57 :note<=8'd26;
	56 :note<=8'd26;
	55 :note<=8'd26;
	54 :note<=8'd26;
	53 :note<=8'd26;
	52 :note<=8'd27;
	51 :note<=8'd27;
	50 :note<=8'd27;
	49 :note<=8'd27;
	48 :note<=8'd27;
	47 :note<=8'd27;
	46 :note<=8'd27;
	45 :note<=8'd28;
	44 :note<=8'd28;
	43 :note<=8'd28;
	42 :note<=8'd28;
	41 :note<=8'd28;
	40 :note<=8'd28;
	39 :note<=8'd28;
	38 :note<=8'd29;
	37 :note<=8'd29;
	36 :note<=8'd29;
	35 :note<=8'd29;
	34 :note<=8'd29;
	33 :note<=8'd29;
	32 :note<=8'd29;
	31 :note<=8'd30;
	30 :note<=8'd30;
	29 :note<=8'd30;
	28 :note<=8'd30;
	27 :note<=8'd30;
	26 :note<=8'd30;
	25 :note<=8'd30;
	24 :note<=8'd31;
	23 :note<=8'd31;
	22 :note<=8'd31;
	21 :note<=8'd31;
	20 :note<=8'd31;
	19 :note<=8'd31;
	18 :note<=8'd31;
	17 :note<=8'd32;
	16 :note<=8'd32;
	15 :note<=8'd32;
	14 :note<=8'd32;
	13 :note<=8'd32;
	12 :note<=8'd32;
	11 :note<=8'd32;
	10 :note<=8'd33;
	9 :note<=8'd33;
	8 :note<=8'd33;
	7 :note<=8'd33;
	6 :note<=8'd33;
	5 :note<=8'd33;
	4 :note<=8'd33;
	3 :note<=8'd34;
	2 :note<=8'd34;
	1 :note<=8'd34;
	default: note <= 8'd05;
endcase
endmodule

/////////////////////////////////////////////////////
