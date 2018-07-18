`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:50:13 07/17/2018 
// Design Name: 
// Module Name:    sync_pre_proces 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sync_pre_process(
		input		clk,
		input		reset_n,
		input 		ext_hsync_i,
		input 		ext_vsync_i,
		output		hsync_redge_o,
		output		vsync_redge_o,
		output		hsync_fedge_o,
		output		vsync_fedge_o
    );
	parameter						DLY_WIDTH = 12;
	
	reg 							hsync_temp;
	reg 							vsync_temp;
	reg		[DLY_WIDTH-1:0] 		hsync_shift;
	reg		[DLY_WIDTH-1:0] 		vsync_shift;
		
	always@(posedge clk or negedge reset_n)begin						//缓存
		if(~reset_n)begin
			hsync_shift		<=	0;
			vsync_shift		<=	0;
		end
		else begin
			hsync_shift		<=	{hsync_shift[DLY_WIDTH-2:0],ext_hsync_i};
			vsync_shift		<=	{vsync_shift[DLY_WIDTH-2:0],ext_vsync_i};
		end
	end
	
	always@(posedge clk or negedge reset_n)begin						//同步信号去抖
		if(~reset_n)begin
			hsync_temp		<=	1;
			vsync_temp		<=	1;
		end
		else begin
			hsync_temp		<=	hsync_shift[4] || hsync_shift[6];			//参数需要根据实际信号的波动调节 以去除同步信号抖动
			vsync_temp		<=	vsync_shift[4] || vsync_shift[6];
		end
	end

	reg	hsync_r;
	reg vsync_r;
	always@(posedge clk)begin
		   hsync_r			<= hsync_temp;
		   vsync_r			<= vsync_temp;
	end
	
	assign hsync_redge_o		= (~hsync_r) & hsync_temp;   //提取边沿       
	assign vsync_redge_o		= (~vsync_r) & vsync_temp;
	assign hsync_fedge_o		= hsync_r & (~hsync_temp);
	assign vsync_fedge_o		= vsync_r & (~vsync_temp);
endmodule
