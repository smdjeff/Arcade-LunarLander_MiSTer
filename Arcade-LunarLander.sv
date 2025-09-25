module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;


wire [1:0] ar = status[15:14];
assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.LLANDER;;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"-;",
	"OD,Thruster,Analog Stick,D-Pad;",
	"-;",
	"O7,Test,Off,On;",
	"O89,Language,English,Spanish,French,German;",
	"OAC,Fuel,450,600,750,900,1100,1300,1550,1800;",
	"-;",
	"R0,Reset;",
	"J1,Start,Select,Coin,Abort,Turn Right,Turn Left;",	
    "jn,Start,Select,X,A,L,R;",
	"DEFMRA,/_Arcade/Lunar Lander.mra;", // causes the HPC side to reload the roms for us
	"V,v",`BUILD_DATE
};
// 00010000
// on is 0
//wire [7:0] m_dip = {~status[12:11],1'b1,~status[10],~status[9:8],1'b0,1'b0};
wire [7:0] m_dip = {1'b0,1'b0,status[8],status[9],~status[10],1'b1,status[11],status[12]};
//wire [7:0] m_dip = 8'b00010000;

////////////////////   CLOCKS   ///////////////////

wire clk_6, clk_25,clk_50;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_50),	
	.outclk_1(clk_25),	
	.outclk_2(clk_6),	
	.locked(pll_locked)
);


///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joy_0, joy_1;
wire [15:0] joy = joy_0 | joy_1;
wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_25),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.joystick_l_analog_0(analog_joy_0)
);

`ifndef MISTER_VECTOR

wire hblank, vblank;
wire ohblank, ovblank;

wire hs, vs;
wire ohs, ovs;
wire [2:0] r,g,b;
wire [7:0] outr,outg,outb;



reg ce_pix;
always @(posedge clk_50) begin
       ce_pix <= !ce_pix;
end
reg [3:0] r2;
reg [3:0] g2;
reg [3:0] b2;

always @(posedge clk_50) begin
    r2<=outr[7:5];
	 g2<=outg[7:5];
    b2<=outb[7:5];
end

arcade_video #(640,12) arcade_video
(
        .*,

        .clk_video(clk_50),

        .RGB_in({r2,g2,b2}),

        .HBlank(ohblank),
        .VBlank(ovblank),
        .HSync(ohs),
        .VSync(ovs),

        .forced_scandoubler(0),
        .fx(0)
);



ovo #(.COLS(1), .LINES(1), .RGB(24'hFF00FF)) diff (
	.i_r({r,r,r[2:1]}),
	.i_g({g,g,g[2:1]}),
	.i_b({b,b,b[2:1]}),
	.i_hs(~hs),
	.i_vs(~vs),
	.i_de(vgade),
	.i_hblank(hblank),
	.i_vblank(vblank),
	.i_en(ce_pix),
	.i_clk(clk_50),

	.o_r(outr),
	.o_g(outg),
	.o_b(outb),
	.o_hs(ohs),
	.o_vs(ovs),
	.o_de(ode),
	.o_hblank(ohblank),
	.o_vblank(ovblank),

	.ena(diff_count > 0),

	.in0(difficulty),
	.in1()
);

`endif

wire lamp2, lamp3, lamp4, lamp5;

wire [1:0] difficulty;

always_comb begin
	if(lamp5)
		difficulty = 2'd3;
	else if(lamp4)
		difficulty = 2'd2;
	else if(lamp3)
		difficulty = 2'd1;
	else
		difficulty = 2'd0;
end

int diff_count = 0;
always @(posedge CLK_50M) begin
	if (diff_count > 0)
		diff_count <= diff_count - 1;
	
	if (~in_select)
		diff_count <= 'd500_000_000; // 10 seconds
end


wire reset = (RESET | status[0] | buttons[1] | ioctl_download);
wire [7:0] audio;
assign AUDIO_L = {audio, audio};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
wire vgade;
wire [15:0] analog_joy_0;

wire signed [7:0] signedjoy = analog_joy_0[15:8];
wire signed [7:0] signedturn = analog_joy_0[7:0];
wire [8:0] us_joy = 9'sd255 - (signedjoy + 9'sd128);


// According to mame, because of the way the DAC worked for the thrust lever,
// it was unlikely that the board ever expected to get 0xFF, so we limit to 0xFE.
wire [8:0] us_joy_mod = us_joy > 9'd254 ? 9'd254 : us_joy;

reg [7:0] dpad_thrust = 0;

// 1 second = 50,000,000 cycles (duh)
// If we want to go from zero to full throttle in 1 second we tick every
// 196,850 cycles.
always @(posedge CLK_50M) begin :thrust_count
	int thrust_count;
	thrust_count <= thrust_count + 1'd1;

	if (thrust_count == 'd196_850) begin
		thrust_count <= 0;
		if ((joy[2]) && dpad_thrust > 0)
			dpad_thrust <= dpad_thrust - 1'd1;

		if ((joy[3]) && dpad_thrust < 'd254)
			dpad_thrust <= dpad_thrust + 1'd1;
	end
end

wire joy_turn_l = (signedturn < -8'sd64);
wire joy_turn_r = (signedturn > 8'sd64);

//4     5      6    7     8          9
//Start,Select,Coin,Abort,Turn Right,Turn Left

wire in_select = ~(joy[5] );
wire in_start  = ~(joy[4] );
wire in_turn_l = ~(joy[9] | joy[1] );
wire in_turn_r = ~(joy[8] | joy[0] );
wire in_coin   = ~(joy[6] );
wire in_abort  = ~(joy[7] );

wire [7:0] in_thrust = status[13] ? dpad_thrust : us_joy_mod;

wire is_starting;

`ifdef MISTER_VECTOR

  // game is outputting 10bit dac
  // VGA_RGB internal ports are 8
  // but hardware DAC is only the 6 lsb pins [5:0]

// input
// 10-bit unsigned inputs from the game core
wire [9:0] x_dac10;
wire [9:0] y_dac10;
wire [3:0] z_dac4;

// output
// 6-bit r2r dac, but pwm'd to 10
wire [5:0] z6 = (z_dac4 == 0) ? 6'h3f : 6'h00;  // binary, on/off for scope
wire [5:0] x6, y6;
sd10to6 sd_x(.clk(CLK_50M), .in(x_dac10), .out(x6));
sd10to6 sd_y(.clk(CLK_50M), .in(y_dac10), .out(y6));

// drive 6-bit ladder every clk
always @(posedge CLK_50M) begin
    VGA_B <= x6;  // X on Blue
    VGA_R <= y6;  // Y on Red
    VGA_G <= z6;  // intensity on Green
end


`endif


LLANDER_TOP LLANDER_TOP
(
	.ROT_LEFT_L(in_turn_l),
	.ROT_RIGHT_L(in_turn_r),
	.ABORT_L(in_abort),
	.GAME_SEL_L(in_select),
	.START_L(in_start),
	.COIN1_L(in_coin),
	.COIN2_L(in_coin),
	.THRUST(in_thrust),
	.DIAG_STEP_L(m_diag_step),
	.SLAM_L(m_slam),
	.SELF_TEST_L(~status[7]), 
	.START_SEL_L(is_starting),
	.LAMP2(lamp2),
	.LAMP3(lamp3),
	.LAMP4(lamp4),
	.LAMP5(lamp5),

	.AUDIO_OUT(audio),
	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

// vector outs	
	.VECTOR_X( x_dac10 ),
	.VECTOR_Y( y_dac10 ),
	.VECTOR_Z( z_dac4 ),

// raster outs		
	.VIDEO_R_OUT(r),
	.VIDEO_G_OUT(g),
	.VIDEO_B_OUT(b),
	
	.HSYNC_OUT(hs),
	.VSYNC_OUT(vs),
	.VGA_DE(vgade),
	.VID_HBLANK(hblank),
	.VID_VBLANK(vblank),
	.DIP(m_dip),
	.RESET_L (~reset),	
	.clk_6(clk_6),
	.clk_25(clk_25)
);

endmodule

// First-order sigma-delta (10-bit -> 6-bit)
module sd10to6 (
  input  wire       clk,
  input  wire [9:0] in,   // 0..1023 (unsigned)
  output reg  [5:0] out   // 0..63   (to 6-bit R-2R ladder)
);
  // Split input into coarse MSBs and 4-bit fraction
  wire [5:0] coarse = in[9:4];
  wire [3:0] frac   = in[3:0];

  // Residual accumulator (0..15)
  reg  [3:0] acc = 4'd0;

  // Current-cycle sum & carry (combinational)
  wire [4:0] s     = acc + frac;  // 0..31
  wire       carry = s[4];        // >=16?
  wire [3:0] res   = s[3:0];      // s - 16 if carry, else s

  always @(posedge clk) begin
    // Emit coarse or coarse+1 this tick (with saturation)
    if (carry)
      out <= (coarse == 6'd63) ? 6'd63 : (coarse + 6'd1);
    else
      out <= coarse;

    // Update residual for next tick
    acc <= res;
  end
endmodule


