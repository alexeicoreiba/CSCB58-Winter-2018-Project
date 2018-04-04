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


// Source is http://www.fpga4fun.com/MusicBox4.html, modified ofcourse to suit our own use

/////////////////////////////////////////////////////////////
module music(
	input clk,
	output reg speaker,
	input [7:0] distance
);



wire [7:0] fullnote;
notemux get_fullnote(.clk(clk), .address(distance[7:0]), .note(fullnote));

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


module notemux(clk, distance, sound);
	
	input clk;
	input [7:0] distance;
	output reg [7:0] sound;

always @(posedge clk)
	case(distance)
	0 :sound<=8'd05;
	1 :sound<=8'd06;
	2 :sound<=8'd06;
	3 :sound<=8'd06;
	4 :sound<=8'd06;
	5 :sound<=8'd06;
	6 :sound<=8'd06;
	7 :sound<=8'd06;
	8 :sound<=8'd07;
	9 :sound<=8'd07;
	10 :sound<=8'd07;
	11 :sound<=8'd07;
	12 :sound<=8'd07;
	13 :sound<=8'd07;
	14 :sound<=8'd07;
	15 :sound<=8'd08;
	16 :sound<=8'd08;
	17 :sound<=8'd08;
	18 :sound<=8'd08;
	19 :sound<=8'd08;
	20 :sound<=8'd08;
	21 :sound<=8'd08;
	22 :sound<=8'd09;
	23 :sound<=8'd09;
	24 :sound<=8'd09;
	25 :sound<=8'd09;
	26 :sound<=8'd09;
	27 :sound<=8'd09;
	28 :sound<=8'd09;
	29 :sound<=8'd10;
	30 :sound<=8'd10;
	31 :sound<=8'd10;
	32 :sound<=8'd10;
	33 :sound<=8'd10;
	34 :sound<=8'd10;
	35 :sound<=8'd10;
	36 :sound<=8'd11;
	37 :sound<=8'd11;
	38 :sound<=8'd11;
	39 :sound<=8'd11;
	40 :sound<=8'd11;
	41 :sound<=8'd11;
	42 :sound<=8'd11;
	43 :sound<=8'd12;
	44 :sound<=8'd12;
	45 :sound<=8'd12;
	46 :sound<=8'd12;
	47 :sound<=8'd12;
	48 :sound<=8'd12;
	49 :sound<=8'd12;
	50 :sound<=8'd13;
	51 :sound<=8'd13;
	52 :sound<=8'd13;
	53 :sound<=8'd13;
	54 :sound<=8'd13;
	55 :sound<=8'd13;
	56 :sound<=8'd13;
	57 :sound<=8'd14;
	58 :sound<=8'd14;
	59 :sound<=8'd14;
	60 :sound<=8'd14;
	61 :sound<=8'd14;
	62 :sound<=8'd14;
	63 :sound<=8'd14;
	64 :sound<=8'd15;
	65 :sound<=8'd15;
	66 :sound<=8'd15;
	67 :sound<=8'd15;
	68 :sound<=8'd15;
	69 :sound<=8'd15;
	70 :sound<=8'd15;
	71 :sound<=8'd16;
	72 :sound<=8'd16;
	73 :sound<=8'd16;
	74 :sound<=8'd16;
	75 :sound<=8'd16;
	76 :sound<=8'd16;
	77 :sound<=8'd16;
	78 :sound<=8'd17;
	79 :sound<=8'd17;
	80 :sound<=8'd17;
	81 :sound<=8'd17;
	82 :sound<=8'd17;
	83 :sound<=8'd17;
	84 :sound<=8'd17;
	85 :sound<=8'd18;
	86 :sound<=8'd18;
	87 :sound<=8'd18;
	88 :sound<=8'd18;
	89 :sound<=8'd18;
	90 :sound<=8'd18;
	91 :sound<=8'd18;
	92 :sound<=8'd19;
	93 :sound<=8'd19;
	94 :sound<=8'd19;
	95 :sound<=8'd19;
	96 :sound<=8'd19;
	97 :sound<=8'd19;
	98 :sound<=8'd19;
	99 :sound<=8'd20;
	100 :sound<=8'd20;
	101 :sound<=8'd20;
	102 :sound<=8'd20;
	103 :sound<=8'd20;
	104 :sound<=8'd20;
	105 :sound<=8'd20;
	106 :sound<=8'd21;
	107 :sound<=8'd21;
	108 :sound<=8'd21;
	109 :sound<=8'd21;
	110 :sound<=8'd21;
	111 :sound<=8'd21;
	112 :sound<=8'd21;
	113 :sound<=8'd22;
	114 :sound<=8'd22;
	115 :sound<=8'd22;
	116 :sound<=8'd22;
	117 :sound<=8'd22;
	118 :sound<=8'd22;
	119 :sound<=8'd22;
	120 :sound<=8'd23;
	121 :sound<=8'd23;
	122 :sound<=8'd23;
	123 :sound<=8'd23;
	124 :sound<=8'd23;
	125 :sound<=8'd23;
	126 :sound<=8'd23;
	127 :sound<=8'd24;
	128 :sound<=8'd24;
	129 :sound<=8'd24;
	130 :sound<=8'd24;
	131 :sound<=8'd24;
	132 :sound<=8'd24;
	133 :sound<=8'd24;
	134 :sound<=8'd25;
	135 :sound<=8'd25;
	136 :sound<=8'd25;
	137 :sound<=8'd25;
	138 :sound<=8'd25;
	139 :sound<=8'd25;
	140 :sound<=8'd25;
	141 :sound<=8'd26;
	142 :sound<=8'd26;
	143 :sound<=8'd26;
	144 :sound<=8'd26;
	145 :sound<=8'd26;
	146 :sound<=8'd26;
	147 :sound<=8'd26;
	148 :sound<=8'd27;
	149 :sound<=8'd27;
	150 :sound<=8'd27;
	151 :sound<=8'd27;
	152 :sound<=8'd27;
	153 :sound<=8'd27;
	154 :sound<=8'd27;
	155 :sound<=8'd28;
	156 :sound<=8'd28;
	157 :sound<=8'd28;
	158 :sound<=8'd28;
	159 :sound<=8'd28;
	160 :sound<=8'd28;
	161 :sound<=8'd28;
	162 :sound<=8'd29;
	163 :sound<=8'd29;
	164 :sound<=8'd29;
	165 :sound<=8'd29;
	166 :sound<=8'd29;
	167 :sound<=8'd29;
	168 :sound<=8'd29;
	169 :sound<=8'd30;
	170 :sound<=8'd30;
	171 :sound<=8'd30;
	172 :sound<=8'd30;
	173 :sound<=8'd30;
	174 :sound<=8'd30;
	175 :sound<=8'd30;
	176 :sound<=8'd31;
	177 :sound<=8'd31;
	178 :sound<=8'd31;
	179 :sound<=8'd31;
	180 :sound<=8'd31;
	181 :sound<=8'd31;
	182 :sound<=8'd31;
	183 :sound<=8'd32;
	184 :sound<=8'd32;
	185 :sound<=8'd32;
	186 :sound<=8'd32;
	187 :sound<=8'd32;
	188 :sound<=8'd32;
	189 :sound<=8'd32;
	190 :sound<=8'd33;
	191 :sound<=8'd33;
	192 :sound<=8'd33;
	193 :sound<=8'd33;
	194 :sound<=8'd33;
	195 :sound<=8'd33;
	196 :sound<=8'd33;
	197 :sound<=8'd34;
	198 :sound<=8'd34;
	199 :sound<=8'd34;
	default: sound <= 8'd34;
endcase
endmodule
