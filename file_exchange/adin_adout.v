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
`define SIMULATE     1
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
		
	parameter       WAIT_VS_REDGE    	=   `STAT_WIDTH'h1,           //等待vs同步信号状态
					WAIT_HS_REDGE    	=   `STAT_WIDTH'h2,           //等待hs同步信号状态
					DELAY    			=   `STAT_WIDTH'h3,           //hs同步信号延迟状态
					SAMPLE				=   `STAT_WIDTH'h4            //采样状态
					;
    
    parameter       SAMPLE_RATE_1M      =    2'd0,
                    SAMPLE_RATE_2M      =    2'd1,
                    SAMPLE_RATE_5M      =    2'd2,
                    SAMPLE_RATE_10M     =    2'd3
                    ;

    `ifdef          SIMULATE
        parameter       hs_num_in_vs      =    8'd20                     //一帧中的行数(仿真)
                    ;
    `else
        parameter       hs_num_in_vs      =    8'd90                     //一帧中的行数
                    ;
    `endif

	reg 		[`STAT_WIDTH-1:0]	state;
	reg			[31:0] 				delay_cnt;                      //延迟计数 用于行同步信号处延迟
    reg         [31:0]              delay_count_i_reg;              //用于在 vs 上升边沿锁存输入 wire 变量 防止变化     
    reg         [ 1:0]              sample_rate_i_reg;              //用于在 vs 上升边沿锁存输入 wire 变量 防止变化
    reg         [31:0]              sample_rate_cnt;                //输入采样计数 分为每 50/25/10/5 点采样
    reg                             sample_origin_fifo_wena = 32'b0;
	always@(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			state		            <=          WAIT_VS_REDGE;
			delay_cnt	            <=          32'b0;
            sample_rate_cnt         <=          32'b0;
			vs_cnt		            <=          6'b0;
			hs_cnt		            <=          10'b0;
            delay_count_i_reg       <=          32'b0;
            sample_rate_i_reg       <=          32'b0;
		end
		else begin
			case(state)
				WAIT_VS_REDGE:begin
					if(vsync_redge == 1)begin //vs 上升沿有效
						state 		            <=          WAIT_HS_REDGE; 
						vs_cnt		            <=          vs_cnt+1'b1;
                        delay_count_i_reg       <=          delay_count_i;
                        sample_rate_i_reg       <=          sample_rate_i;
					end
					else
						state 		<= WAIT_VS_REDGE;
				end
				
				WAIT_HS_REDGE:begin
					if(hsync_redge == 1)begin
						// if(hs_cnt == (hs_num_in_vs + 8'b1))
						// 	state		<= WAIT_VS_REDGE;  //当 91 (第91行)同步信号到来时 标志着一帧(90行)采集完毕 将状态转入 等待 vs 的状态
						// else begin
						// 	hs_cnt		<= hs_cnt + 1'b1;  
						// 	state 		<= DELAY;   //转入状态 DELAY 度过每行前的延迟
						// end
                        state 		<= DELAY;
					end
					else
						state 		<= WAIT_HS_REDGE;
				end
				
				DELAY:begin
					if(delay_cnt > delay_count_i_reg)begin//行同步延迟计数
						state		<= SAMPLE;
						delay_cnt	<= 0;
					end
					else begin
						state		<= DELAY;
						delay_cnt	<= delay_cnt+1'b1;
					end
				end
				
				
				SAMPLE:begin
					if(hsync_redge == 1) //
                        sample_rate_cnt <= 32'b0;//新一行同步信号到来 清零采样计数器
                        if (hs_cnt == (hs_num_in_vs + 8'b1 )) begin
                           state		<= WAIT_VS_REDGE;  //当 91 (第91行)同步信号到来时 标志着一帧(90行)采集完毕 将状态转入 等待 vs 的状态 
                        end
                        else begin
                            state   <= DELAY;//转入 DELAY 状态
                        end
					else begin//从ADC模块获取ADC值 位序反置
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

                        sample_rate_cnt <= sample_rate_cnt + 32'b1;                   
                        case(sample_rate_i_reg)//根据采样率 输出对应频率的 fifo 写使能
                            SAMPLE_RATE_1M:begin    //1M
                                if(sample_rate_cnt == 32'd49) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_2M:begin    //2M
                                if(sample_rate_cnt == 32'd24) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    //sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_5M:begin    //5M
                                if(sample_rate_cnt == 32'd9) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    //sample_rate_cnt <= sample_rate_cnt + 32'b1;
                                    sample_origin_fifo_wena <= 1'b0;
                                end
                            end
                            SAMPLE_RATE_10M:begin   //10M
                                if(sample_rate_cnt == 32'd4) begin
                                    sample_rate_cnt <= 32'b0;
                                    sample_origin_fifo_wena <= 1'b1;
                                end
                                else begin
                                    //sample_rate_cnt <= sample_rate_cnt + 32'b1;
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
//DEBUG:在外部模块未就绪的情况下 提供初始值
assign delay_count_i = 32'd100;
assign sample_rate_i = 2'b1;

//输出
assign sample_origin_fifo_wena_o = sample_origin_fifo_wena;

endmodule
