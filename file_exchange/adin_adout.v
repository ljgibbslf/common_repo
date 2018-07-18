`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:13:36 07/09/2018 
// Design Name: 
// Module Name:    adin_adout 
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
`define STAT_WIDTH   10

module adin_adout(
	//
	input 				clk,
	input 				rst_n,
	input 				hsync_redge,	
	input 				vsync_redge,
	input 				hsync_fedge,
	input 				vsync_fedge,
	input 		[11:0]	ad_in,
	input		[31:0]	delay_count_i,
    input       [ 1:0]  sample_rate_i,
    output              sample_origin_fifo_wena_o,
	output reg  [11:0]	addata_o=0,
	output reg  [5:0]	vs_cnt, 
	output reg  [9:0]	hs_cnt
 );
		
	parameter       WAIT_VS_REDGE    	= `STAT_WIDTH'h1,           //等待vs同步信号状态
					WAIT_HS_REDGE    	= `STAT_WIDTH'h2,           //等待hs同步信号状态
					DELAY    			= `STAT_WIDTH'h3,           //hs同步信号延迟状态
					SAMPLE				= `STAT_WIDTH'h4            //采样状态
					;
    
    parameter       SAMPLE_RATE_1M =    2'd0,
                    SAMPLE_RATE_2M =    2'd1,
                    SAMPLE_RATE_5M =    2'd2,
                    SAMPLE_RATE_10M =   2'd3
                    ;

	reg 		[`STAT_WIDTH-1:0]	state;
	reg			[31:0] 				delay_cnt;
    reg         [31:0]              sample_rate_cnt;
    reg                             sample_origin_fifo_wena = 0;;
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			state		<= WAIT_VS_REDGE;
			delay_cnt	<= 0;
            sample_rate_cnt <= 0;
			vs_cnt		<= 0;
			hs_cnt		<= 0;
		end
		else begin
			case(state)
				WAIT_VS_REDGE:begin
					if(vsync_redge == 1)begin //vs 上升沿有效
						state 		<= WAIT_HS_REDGE; 
						vs_cnt		<= vs_cnt+1'b1;
					end
					else
						state 		<= WAIT_VS_REDGE;
				end
				
				WAIT_HS_REDGE:begin
					if(hsync_redge == 1)begin
						if(hs_cnt == 90)
							state		<= WAIT_VS_REDGE;  //当 90 (第91帧)同步信号到来时 标志着一帧(90行)采集完毕 将状态转入 等待 vs 的状态
						else begin
							hs_cnt		<= hs_cnt+1'b1; 
							state 		<= DELAY;   //装入 DELAY 度过每行前的延迟
						end
					end
					else
						state 		<= WAIT_HS_REDGE;
				end
				
				DELAY:begin
					if(delay_cnt > delay_count_i)begin//行同步延迟计数
						state		<= SAMPLE;
						delay_cnt	<= 0;
					end
					else begin
						state		<= DELAY;
						delay_cnt	<= delay_cnt+1'b1;
					end
				end
				
				
				SAMPLE:begin
					if(hsync_redge == 1)//上升沿
						state   <= WAIT_HS_REDGE;
                    
					else begin
						addata_o[11]	<=	ad_in[0];
						addata_o[10]	<=	ad_in[1];
						addata_o[9]		<=	ad_in[2];
						addata_o[8]		<=	ad_in[3];
						addata_o[7]		<=	ad_in[4];
						addata_o[6]		<=	ad_in[5];
						addata_o[5]		<=	ad_in[6];
						addata_o[4]		<=	ad_in[7];
						addata_o[3]		<=	ad_in[8];
						addata_o[2]		<=	ad_in[9];
						addata_o[1]		<=	ad_in[10];
						addata_o[0]		<=	ad_in[11];
                        
                        
                        case(sample_rate_i)//根据采样率 输出对应频率的 fifo 写使能
                            SAMPLE_RATE_1M:begin    //1M
                                if(sample_rate_cnt == 50) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_2M:begin    //2M
                                if(sample_rate_cnt == 25) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_5M:begin    //5M
                                if(sample_rate_cnt == 10) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_10M:begin   //10M
                                if(sample_rate_cnt == 50) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            default:
                                sample_origin_fifo_wena <= 1'b0;
                        endcase
					end
				end
				default:state<=WAIT_VS_REDGE;
				endcase	
		end
	
	
	
	
	end

assign delay_count_i = 32'd100;
assign sample_rate_i = 2'b0;
assign sample_origin_fifo_wena_o = sample_origin_fifo_wena;

endmodule
