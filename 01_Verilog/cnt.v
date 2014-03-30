/*
 * Global Counter
 *
 */

`include "acog_defs.v"  
module GblCounter(
	input wire 			clk_in,
	input wire 			reset_in,
	
	output wire [31:0] 	CNT_o);
	
reg [31:0] CNT;

assign CNT_o = CNT;
/* Global counter */
always @(posedge clk_in)
	begin
		if (reset_in)
			CNT <= 0;
		else
			begin
				CNT <= CNT + 1;
			end
	end

initial
	begin
		CNT = 0;
	end
	
endmodule