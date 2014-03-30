/*
 *
 *
 */
 
module tb();

reg clk, reset;
wire [31:0] porta, portb;

//AProp prop(.clk_in(clk), .reset_in(reset), .port_a(porta), .port_b(portb));

ACog cog0(.clk_in(clk), .reset_in(reset));
always 
	#6.25 clk = ~ clk;
	
	
initial
	begin
		$dumpfile("acog.vcd");
		$dumpvars(0, tb);
		clk = 0;
		reset = 1;
		#61
		reset = 0;
		#2000
		$finish;
	end
	
endmodule
