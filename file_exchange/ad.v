`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module ad(
		input 							clk,
		input           				reset_n,
		input 							ext_hsync_i,
		input							ext_vsync_i,
		input [4:0]						sample_clock_i,
		input [31:0]					delay_count_i,
		input [11:0] 					ad1_in,
		output		    				ad1_clk,		//1MHz 2Mhz 5Mhz 10Mhz
 		input [11:0] 					ad2_in,			//第二路ad 未用到
 		output							ad2_clk,
		(* KEEP="TRUE"*)output  [11:0]  ad_ch1,
 		(* KEEP="TRUE"*)output  [11:0]  ad_ch2,
		output							hs_o,
		output							vs_o
		
			 
    );
	
		wire 							hs;
		wire 							vs;
		// wire							clk_1m;
		// wire							clk_2m;
		// wire							clk_5m;
		// wire							clk_10m;
		// wire							clk_50m;
		wire							hsync_fedge;
		wire							vsync_fedge;
		wire							hsync_redge;
		wire							vsync_redge;
		wire                            sample_rate_i;
        wire                            sample_origin_fifo_wena_o;
		assign  ad1_clk	=	clk;

			adin_adout adin_adout_inst(
				.clk			(ad1_clk),
				.rst_n			(reset_n),
				//input
				.hsync_redge	(hsync_redge),
				.vsync_redge	(vsync_redge),
				.hsync_fedge	(hsync_fedge),
				.vsync_fedge	(vsync_fedge),
				.ad_in			(ad1_in),
                .delay_count_i	(delay_count_i),
                .sample_rate_i  (sample_rate_i),
				//output
				.sample_origin_fifo_wena_o (sample_origin_fifo_wena_o),
				.addata_o		(ad_ch1)
                
				// .vs_cnt			()
				// .hs_cnt			()
				);
			
			// clk_manager clk_manager_inst(
				// .clk			(clk),
				// .sample_clock_i	(sample_clock_i),			//上位机采样时钟参数				
				// .clk_50m		(clk_50m),
				// .clk_ad			(ad1_clk)
				// );
				
				
			sync_pre_process sync_pre_process_inst(
				//input
				.clk			(clk),		
				.reset_n		(reset_n),
				.ext_hsync_i	(ext_hsync_i),
				.ext_vsync_i	(ext_vsync_i),
				//output
				.hsync_redge_o	(hsync_redge),
				.vsync_redge_o	(vsync_redge),
				.hsync_fedge_o	(hsync_fedge),
				.vsync_fedge_o	(vsync_fedge)
				);
				

endmodule
