module top (
	input  CLK,
	input BTN_N, BTN1, BTN2, BTN3,
	output LED1, LED2, LED3, LED4, LED5,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
	output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
);
	wire [7:0] seven_segment_top;
	wire [7:0] seven_segment_bot;

	reg [15:0] display_value = 0;
	wire [15:0] display_value_inc;

	assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment_top;
	assign { P1B10, P1B9, P1B8, P1B7, P1B4, P1B3, P1B2, P1B1 } = seven_segment_bot;

	reg [20:0] clkdiv = 0;
	reg clkdiv_pulse = 0;

	assign LED1 = !BTN_N;
	assign LED2 = BTN1 || BTN2;
	assign LED3 = BTN2 ^ BTN3;
	assign LED4 = BTN3 && !BTN_N;
	assign LED5 = (BTN1 + BTN2 + BTN3 + 2'b00) >> 1;

	always @(posedge CLK) begin
		if (clkdiv == 120000) begin
			clkdiv <= 0;
			clkdiv_pulse <= 1;
		end else begin
			clkdiv <= clkdiv + 1;
			clkdiv_pulse <= 0;
		end

		if (clkdiv_pulse) begin
			display_value <= display_value_inc;
		end
	end

	seven_seg_ctrl seven_segment_ctrl_top (
		.CLK(CLK),
		.din(display_value[15:8]),
		.dout(seven_segment_top)
	);

	seven_seg_ctrl seven_segment_ctrl_bot (
		.CLK(CLK),
		.din(display_value[7:0]),
		.dout(seven_segment_bot)
	);

	assign display_value_inc = display_value + 16'b1;
endmodule

module bcd16_increment (
	input [15:0] din,
	output reg [15:0] dout
);
	always @* begin
		case (1'b1)
			din[15:0] == 16'h 9999:
				dout = 0;
			din[11:0] == 12'h 999:
				dout = {din[15:12] + 4'd 1, 12'h 000};
			din[7:0] == 8'h 99:
				dout = {din[15:12], din[11:8] + 4'd 1, 8'h 00};
			din[3:0] == 4'h 9:
				dout = {din[15:8], din[7:4] + 4'd 1, 4'h 0};
			default:
				dout = {din[15:4], din[3:0] + 4'd 1};
		endcase
	end
endmodule

module seven_seg_ctrl (
	input CLK,
	input [7:0] din,
	output reg [7:0] dout
);
	wire [6:0] lsb_digit;
	wire [6:0] msb_digit;

	seven_seg_hex msb_nibble (
		.din(din[7:4]),
		.dout(msb_digit)
	);

	seven_seg_hex lsb_nibble (
		.din(din[3:0]),
		.dout(lsb_digit)
	);

	reg [9:0] clkdiv = 0;
	reg clkdiv_pulse = 0;
	reg msb_not_lsb = 0;

	always @(posedge CLK) begin
		clkdiv <= clkdiv + 1;
		clkdiv_pulse <= &clkdiv;
		msb_not_lsb <= msb_not_lsb ^ clkdiv_pulse;

		if (clkdiv_pulse) begin
			if (msb_not_lsb) begin
				dout[6:0] <= ~msb_digit;
				dout[7] <= 0;
			end else begin
				dout[6:0] <= ~lsb_digit;
				dout[7] <= 1;
			end
		end
	end
endmodule

module seven_seg_hex (
	input [3:0] din,
	output reg [6:0] dout
);
	always @*
		case (din)
			4'h0: dout = 7'b 0111111;
			4'h1: dout = 7'b 0000110;
			4'h2: dout = 7'b 1011011;
			// 4'h3: dout = FIXME;
			4'h4: dout = 7'b 1100110;
			4'h5: dout = 7'b 1101101;
			4'h6: dout = 7'b 1111101;
			4'h7: dout = 7'b 0000111;
			// 4'h8: dout = FIXME;
			4'h9: dout = 7'b 1101111;
			4'hA: dout = 7'b 1110111;
			4'hB: dout = 7'b 1111100;
			4'hC: dout = 7'b 0111001;
			4'hD: dout = 7'b 1011110;
			4'hE: dout = 7'b 1111001;
			4'hF: dout = 7'b 1110001;
			default: dout = 7'b 1000000;
		endcase
endmodule
