
module tb_addabs();

reg clk, C, Z;
reg [31:0] S, D;
wire [31:0] addabs, subabs;
wire addabs_c, subabs_c;
wire sub_c, add_c, sum_c;

wire [31:0] abs;
wire [31:0] sub, add, sum;

assign abs = S[31] ? 32'h0-S:S;

assign { addabs_c, addabs } = D + abs;
assign { subabs_c, subabs } = D - abs;
assign { add_c, add } = D + S;
assign { sub_c, sub } = D - S;

acog_sum sumx(.opcode_in(6'h0),
	.s_in(S),
	.s_negative_in(32'h0-S),
	.d_in(D),
	.flag_c_in(C),
	.flag_z_in(Z),
	.q_o(sum),
	.flag_c_o(sum_c)
	);

initial
	begin
	//$dumpfile("tb_alu.vcd");
	//$dumpvars(0, tb_alu);
	$display("---D---- ---S---- = C--ADDABS-  C--SUBABS-  C---ADD---  C---SUB---");
	#1
	S = 32'h00000004;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'h00000003;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'h00000002;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFF;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFE;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFD;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFC;
	D = 32'hFFFFFFFD;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	$display("---D---- ---S---- = C--ADDABS-  C--SUBABS-  C---ADD---  C---SUB---");
	
	#1
	S = 32'hFFFFFFFC;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFD;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFE;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'hFFFFFFFF;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'h00000002;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'h00000003;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	S = 32'h00000004;
	D = 32'h00000003;
	#1 $display("%08x %08x = %1x %08x  %1x %08x  %1x %08x  %1x %08x", D, S, addabs_c, addabs, subabs_c, subabs, add_c, add, sub_c, sub);
	
	$display("---D---- ---S---- ZC = --SUM---  ZC");
	#1
	D = 32'h00000001;
	S = 32'h00000001;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'h00000001;
	S = 32'hFFFFFFFF;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'hFFFFFFFF;
	S = 32'hFFFFFFFF;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'hFFFFFFFF;
	S = 32'h00000001;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'h80000000;
	S = 32'h00000001;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'h80000000;
	S = 32'hFFFFFFFF;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'h7fffffff;
	S = 32'hFFFFFFFF;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	#1
	D = 32'h7FFFFFFF;
	S = 32'h00000001;
	C = 0; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 0; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 0;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	C = 1; Z = 1;
	#1 $display("%08x %08x %1x%1x = %08x  %1x%1x", D, S, Z, C, sum, sum==32'h0, sum_c);
	
	end
	
endmodule


module acog_sum(
	input wire [5:0] opcode_in,
	input wire [31:0] s_in,
	input wire [31:0] s_negative_in,
	input wire [31:0] d_in,
	input wire flag_c_in,
	input wire flag_z_in,
	output reg [31:0] q_o,
	output reg flag_c_o
	);

wire [31:0] q_sum, q_sum_n;
wire sv, svn;

assign q_sum = d_in + s_in;
assign q_sum_n = d_in + s_negative_in;
assign sv = (d_in[31] & s_in[31] & (!q_sum[31])) | ((!d_in[31]) & (!s_in[31]) & q_sum[31]);
assign svn = (d_in[31] & s_negative_in[31] & (!q_sum_n[31])) | ((!d_in[31]) & (!s_negative_in[31]) & q_sum_n[31]);

always @(*)
	begin
		case (opcode_in[1:0])
			2'b00: q_o = flag_c_in ? q_sum_n:q_sum; // SUMC = D + (-S) if C or D + S if !C
			2'b01: q_o = flag_c_in ? q_sum:q_sum_n; // SUMNC
			2'b10: q_o = flag_z_in ? q_sum_n:q_sum; // SUMZ
			2'b11: q_o = flag_z_in ? q_sum:q_sum_n; // SUMNC
		endcase
	end
			
always @(*)
	begin
		case (opcode_in[1:0])
			2'b00: flag_c_o = flag_c_in ? svn:sv;
			2'b01: flag_c_o = flag_c_in ? sv:svn;
			2'b10: flag_c_o = flag_z_in ? svn:sv;
			2'b11: flag_c_o = flag_z_in ? sv:svn;
		endcase
	end
endmodule

/*
                    ------- C  A  L  C  U  L  A  T  E  D ---------   ----- R  E  A  L -----
---D---- ---S---- = C--ADDABS-  C--SUBABS-  C---ADD---  C---SUB---   C--ADDABS-  C--SUBABS-  
fffffffd 00000004 = 1 00000001  0 fffffff9  1 00000001  0 fffffff9   1 00000001              
fffffffd 00000003 = 1 00000000  0 fffffffa  1 00000000  0 fffffffa   1 00000000              
fffffffd 00000002 = 0 ffffffff  0 fffffffb  0 ffffffff  0 fffffffb   0 ffffffff              
fffffffd ffffffff = 0 fffffffe  0 fffffffc  1 fffffffc  1 fffffffe   1 fffffffe              
fffffffd fffffffe = 0 ffffffff  0 fffffffb  1 fffffffb  1 ffffffff   1 ffffffff              
fffffffd fffffffd = 1 00000000  0 fffffffa  1 fffffffa  0 00000000   0 00000000              
fffffffd fffffffc = 1 00000001  0 fffffff9  1 fffffff9  0 00000001   0 00000001              
---D---- ---S---- = C--ADDABS-  C--SUBABS-  C---ADD---  C---SUB---   C--ADDABS-  C--SUBABS-  
00000003 fffffffc = 0 00000007  1 ffffffff  0 ffffffff  1 00000007               0 ffffffff  
00000003 fffffffd = 0 00000006  0 00000000  1 00000000  1 00000006               1 00000000  
00000003 fffffffe = 0 00000005  0 00000001  1 00000001  1 00000005               1 00000001  
00000003 ffffffff = 0 00000004  0 00000002  1 00000002  1 00000004               1 00000002  
00000003 00000002 = 0 00000005  0 00000001  0 00000005  0 00000001               0 00000001  
00000003 00000003 = 0 00000006  0 00000000  0 00000006  0 00000000               0 00000000  
00000003 00000004 = 0 00000007  1 ffffffff  0 00000007  1 ffffffff               1 ffffffff  
*/