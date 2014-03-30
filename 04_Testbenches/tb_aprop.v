/* Testbench for AProp
 * (c) 2014 Alejndro Paz Schmidt
 * run with icarus verilog
 *
 * ./sim_aprop.sh
 */
 
module tb();

reg clk, reset;
wire [31:0] porta, portb;

AProp prop(.clk_in(clk), .reset_in(reset), .port_a(porta));//, .port_b(portb));

//ACog cog0(.clk_in(clk), .reset_in(reset));
always 
	#6.25 clk = ~ clk;
	
	
initial
	begin
		$dumpfile("aprop.vcd");
		$dumpvars(0, tb);
		clk = 0;
		reset = 1;
		#61
		reset = 0;
		#160000
		$finish;
	end
	
endmodule