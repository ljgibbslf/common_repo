`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:08:14 07/17/2018
// Design Name:   ad
// Module Name:   C:/Project/wave/wavelet/ise/vtf_ad.v
// Project Name:  ise
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ad
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module vtf_ad;

	// Inputs
	reg clk;
	reg reset_n;
	reg ext_hsync_i;
	reg ext_vsync_i;
	reg [4:0] sample_clock_i;
	reg [31:0]delay_count_i;
	reg [11:0] ad1_in;
	reg [11:0] ad2_in;

	// Outputs
	wire ad1_clk;
	wire ad2_clk;
	wire [11:0] ad_ch1;
	wire [11:0] ad_ch2;
	wire hs_o;
	wire vs_o;

	// Instantiate the Unit Under Test (UUT)
	ad uut (
		.clk(clk), 
		.reset_n(reset_n), 
		.ext_hsync_i(ext_hsync_i), 
		.ext_vsync_i(ext_vsync_i), 
		.sample_clock_i(sample_clock_i), 
		.ad1_in(ad1_in), 
		.ad1_clk(ad1_clk), 
		.ad2_in(ad2_in), 
		.ad2_clk(ad2_clk), 
		.ad_ch1(ad_ch1), 
		.ad_ch2(ad_ch2), 
		.hs_o(hs_o), 
		.vs_o(vs_o)
	);
    parameter hs_low_period = 700;
    parameter hs_high_period = 13500;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset_n = 0;
		ext_hsync_i = 1;
		ext_vsync_i = 1;
		sample_clock_i = 0;
		ad1_in = 0;
		ad2_in = 0;
		//delay_count_i = 32'd100;
		// Wait 100 ns for global reset to finish
		#100;
		reset_n = 1;
		ad1_in= 12'h0ef;

        repeat(4) begin
            ext_vsync_i=0;
            #700;
            ext_vsync_i=1;
            #18500;

        
            repeat(20) begin
                ad1_in = ad1_in + 12'b1;
                #20;
                ext_hsync_i=0;
                #hs_low_period;
                ext_hsync_i=1;
                #hs_high_period;
            end

            #18500;
        end
  
		
		
		
		
        
		// Add stimulus here
		//#500000;
		//$stop;
	end
      always #10 clk=~clk;
endmodule

