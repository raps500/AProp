/* 
 * ACog - ALU 
 *
 * 
 */
`include "acog_defs.v" 

module acog_alu(
	input wire clk_in,
	//input wire [1:0] state_in,
	input wire [5:0] opcode_in, // only relevant bits
	input wire flag_c_in,
	input wire flag_z_in,
	input wire [31:0] s_in,
	input wire [31:0] s_negative_in,
	input wire [31:0] d_in,
	input wire [31:0] d_lshift_in,
	input wire [31:0] d_rshift_in,
	input wire [31:0] hub_data_in,
	input wire [`MEM_WIDTH-1:0] pc_plus_1_in,
	input wire d_is_zero_in,
	output reg flag_c_o,
	output reg flag_z_o,
	output reg [31:0] q_o
	);

wire [31:0] q_addsub, q_sar, q_shl, q_shr, q_ror, q_rol, q_rev;
wire [31:0] q_logic, q_mux, q_sum, q_rcl, q_rcr;
wire [31:0] s_abs, q_cmps, q_sumxx, s_negated, q_waitcnt;
wire [31:0] q_muls;
wire [32:0] q_cmpsub, q_djnz;
wire flag_c_addsub, flag_c_logic, flag_c_rcl, flag_c_rcr, flag_c_cmps;
wire flag_c_sumxx, flag_uborrow;
wire flag_c_maxs; // MAXS C asserted if d_in < s_in
wire flag_c_waitcnt; // WAITCNT C is unsigned overflow like in ADD
wire q_is_zero; // asserted when the output of the ALU is zero
wire s_is_zero; // s_in equals zero
assign s_abs = s_in[31] ? s_negative_in:s_in; // absolute value
assign s_negated = ~s_in; // all bits negated
assign q_djnz = { 1'b0, d_in } - 33'h01;

acog_addsub addsub(
	.opcode_in(opcode_in),
	.flag_c_in(flag_c_in),
	.s_in(s_in),
	.s_abs_in(s_abs),
	.d_in(d_in),
	.flag_c_o(flag_c_addsub),
	.flag_uborrow_o(flag_uborrow),
	.q_o(q_addsub)
	);

acog_cmpsx cmpsx(
	.opcode_in(opcode_in),
	.flag_c_in(flag_c_in),
	.s_in(s_in),
	.d_in(d_in),
	.flag_c_o(flag_c_cmps),
	.flag_c_maxs_o(flag_c_maxs),
	.q_o(q_cmps)
	);
	
acog_logic alogic(
	.opcode_in(opcode_in),
	.flag_c_in(flag_c_in),
	.flag_z_in(flag_z_in),
	.s_in(s_in),
	.s_negated_in(s_negated),
	.d_in(d_in),
	.flag_c_o(flag_c_logic),
	.q_o(q_logic) );

barrel_rcl rcl(.a(d_in), .flag_c(flag_c_in), .q(q_rcl), .shift(s_in[4:0]));
barrel_rcr rcr(.a(d_in), .flag_c(flag_c_in), .q(q_rcr), .shift(s_in[4:0]));

barrel_rol rol(.a(d_in), .q(q_rol), .shift(s_in[4:0]));
barrel_ror ror(.a(d_in), .q(q_ror), .shift(s_in[4:0]));
barrel_shl shl(.a(d_lshift_in), .q(q_shl), .shift(s_in[4:0]));
barrel_shr shr(.a(d_rshift_in), .q_shr(q_shr), .q_sar(q_sar), .shift(s_in[4:0]));
barrel_rev rev(.d_in(d_in), .s_in(s_in[4:0]), .q_o(q_rev));

acog_sum sumxx(.opcode_in(opcode_in),
	.s_in(s_in),
	.s_negative_in(s_negative_in),
	.d_in(d_in),
	.flag_c_in(flag_c_in),
	.flag_z_in(flag_z_in),
	.q_o(q_sumxx),
	.flag_c_o(flag_c_sumxx) );

`ifdef ALTERA_CV
/* for MUL & MULS 
 * signa/signb are 1 when a&b are signed numbers, uses bit 0 of opcode_in (bit 26 of opcode)
 */

acog_muls muls(
		.result(q_muls),  //  result.result
		.dataa_0(s_in[15:0]), // dataa_0.dataa_0
		.datab_0(d_in[15:0]), // datab_0.datab_0
		.signa(opcode_in[0]),   //   signa.signa
		.signb(opcode_in[0])    //   signb.signb
	);

`endif
	
// BIG Q MUX
always @(*)
	begin
		q_o = s_in; // MOV
		case (opcode_in)
			`I_RDBYTE, `I_RDWORD, `I_RDLONG: q_o = hub_data_in;
			`I_ABS: q_o = s_abs;
			`I_ABSNEG: q_o = s_in[31] ? s_in:s_negative_in;
			`I_ADD, `I_ADDABS, `I_ADDS, `I_ADDSX, `I_ADDX,
			`I_SUB, `I_SUBABS, `I_SUBS, `I_SUBSX, `I_SUBX: q_o = q_addsub;
			`I_AND, `I_ANDN, `I_OR, `I_XOR,
			`I_MUXC, `I_MUXNC, `I_MUXNZ, `I_MUXZ: q_o = q_logic;
			`I_CMPS, `I_CMPSX: q_o = q_cmps; // ok
			//`I_CMPSUB: q_o = q_cmpsub[31:0];
			`I_CMPSUB: q_o = q_addsub;
			`I_DJNZ: q_o = q_djnz[31:0];
			`I_MOVD: q_o = { d_in[31:18], s_in[8:0], d_in[8:0] };
			`I_MOVI: q_o = { s_in[8:0], d_in[22:0] };
			`I_MOVS: q_o = { d_in[31:9], s_in[8:0] };
			`I_MAX: q_o = d_in < s_in ? d_in:s_in;
			`I_MIN: q_o = d_in > s_in ? d_in:s_in;
			`I_MAXS: q_o = flag_c_maxs ? d_in:s_in;
			`I_MINS: q_o = (!flag_c_maxs) ? d_in:s_in;
			`I_MUL,`I_MULS: q_o = q_muls;
			`I_NEG: q_o = s_negative_in;
			`I_NEGC: if (flag_c_in) q_o = s_negative_in;
			`I_NEGNC: if (!flag_c_in) q_o = s_negative_in;
			`I_NEGNZ: if (!flag_z_in) q_o = s_negative_in;
			`I_NEGZ: if (flag_z_in) q_o = s_negative_in;
			`I_RCL: q_o = q_rcl;
			`I_RCR: q_o = q_rcr;
			`I_REV: q_o = q_rev;
			`I_ROL: q_o = q_rol;
			`I_ROR: q_o = q_ror;
			`I_SUMC, `I_SUMNC, `I_SUMZ: q_o = q_sumxx;
			`I_SHL: q_o = q_shl;
			`I_SHR: q_o = q_shr;
			`I_SAR: q_o = q_sar;
			`I_JMPRET: q_o = { 23'b010111_0001_1111_000000000, pc_plus_1_in };
			`I_TJZ, `I_TJNZ: q_o = d_in;
			`I_WAITCNT: q_o = q_addsub;//q_waitcnt;
			default: q_o = s_in; // MOV
		endcase
	end
// BIG C MUX
always @(*)
	begin
		case (opcode_in)
			//`I_ABS: s_in[31];
			//`I_ABSNEG: s_in[31];
			`I_ADD, `I_ADDABS, `I_ADDS, `I_ADDSX, `I_ADDX,
			`I_SUB, `I_SUBABS, `I_SUBS, `I_SUBSX, `I_SUBX: 
					flag_c_o = flag_c_addsub;
			`I_AND, `I_ANDN, `I_OR, `I_XOR,
			`I_MUXC, `I_MUXNC, `I_MUXNZ, `I_MUXZ: 
					flag_c_o = flag_c_logic;
			`I_CMPS, `I_CMPSX: flag_c_o = flag_c_cmps; // borrow
			`I_CMPSUB: flag_c_o = flag_c_addsub;
			`I_DJNZ: flag_c_o = q_djnz[32];
			//`I_NEG, `I_NEGC, `I_NEGNC, `I_NEGNZ, `I_NEGZ: 
			//		flag_c_o = s_in[31];
			`I_MAX,	`I_MIN: flag_c_o = d_in < s_in;
			`I_MAXS,`I_MINS: flag_c_o = flag_c_maxs;
			`I_MOVD, `I_MOVI, `I_MOVS: flag_c_o = flag_uborrow;
			`I_RCL: flag_c_o = d_in[31];
			`I_RCR: flag_c_o = d_in[0];
			`I_REV: flag_c_o = d_in[0];
			`I_ROL: flag_c_o = d_in[31];
			`I_ROR: flag_c_o = d_in[0]; // what happens when shift == 0 ?
			`I_SUMC, `I_SUMNC, `I_SUMZ, `I_SUMNZ: flag_c_o = flag_c_sumxx;
			`I_SHL: flag_c_o = d_in[31];
			`I_SHR: flag_c_o = d_in[0];
			`I_SAR: flag_c_o = d_in[0];
			// `I_TJZ, `I_TNJZ: // undefined behaviour :(
			`I_WAITCNT: flag_c_o = flag_c_addsub;//flag_c_waitcnt;
			default: flag_c_o = s_in[31]; // MOV
		endcase
	end
assign q_is_zero = q_o == 32'h0;
assign s_is_zero = s_in == 32'h0;
// BIG Z MUX
always @(*)
	begin
		case (opcode_in)
			`I_ADDSX, `I_ADDX, `I_SUBSX, `I_SUBX: flag_z_o = (q_addsub == 32'h0) & flag_z_in;
			`I_CMPSX: flag_z_o = (q_cmps == 32'h0) & flag_z_in;
			`I_MAX, `I_MIN, `I_MAXS, `I_MINS: flag_z_o = s_is_zero;
			`I_MOVD, `I_MOVI, `I_MOVS: flag_z_o = d_is_zero_in; // real tests give Z=1 only when the written whole D is zero
			`I_TJZ, `I_TJNZ: flag_z_o = d_is_zero_in; // Original D
			default: flag_z_o = q_is_zero;
		endcase
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

module acog_logic(
	input wire [5:0] opcode_in,
	input wire flag_c_in,
	input wire flag_z_in,
	input wire [31:0] s_in,
	input wire [31:0] s_negated_in,
	input wire [31:0] d_in,
	output reg [31:0] q_o,
	output wire flag_c_o
	);

wire [15:0] odd16;
wire [7:0] odd8;
wire [3:0] odd4;
wire [2:0] odd2;

always @(*)
	case (opcode_in[2:0])
		3'b000: q_o = d_in & s_in;    // AND
		3'b001: q_o = d_in & (~s_in); // ANDN
		3'b010: q_o = d_in | s_in;    // OR
		3'b011: q_o = d_in ^ s_in;    // XOR
		3'b100: q_o = (d_in & s_negated_in) | (flag_c_in ? s_in:32'h0); //`I_MUXC:
		3'b101: q_o = (d_in & s_negated_in) | (!flag_c_in ? s_in:32'h0);//`I_MUXNC:
		3'b110: q_o = (d_in & s_negated_in) | (!flag_z_in ? s_in:32'h0);//`I_MUXNZ:
		3'b111: q_o = (d_in & s_negated_in) | (flag_z_in ? s_in:32'h0); //`I_MUXZ:
	endcase
	
assign odd16 =   q_o[31:16] ^   q_o[15:0];
assign odd8  = odd16[15:8]  ^ odd16[7:0];
assign odd4  =  odd8[7:4]   ^  odd8[3:0];
assign odd2  =  odd4[3:2]   ^  odd4[1:0];
assign flag_c_o = odd2[1]   ^  odd2[0];

endmodule

module acog_addsub(
	input wire [5:0] opcode_in,
	input wire flag_c_in,
	input wire [31:0] s_in,
	input wire [31:0] s_abs_in,
	input wire [31:0] d_in,
	output reg flag_c_o,
	output wire flag_uborrow_o,
	output reg [31:0] q_o
	);

wire x, sv, av;
wire [32:0] partial_add_x, partial_add, partial_sub;
wire [32:0] partial_sub_x;
wire [32:0] q_addabs, q_subabs;

assign x = (opcode_in[4] & opcode_in[1]) ? flag_c_in:1'b0;

assign partial_add = { 1'b0, d_in } + { 1'b0, s_in };
assign partial_add_x = partial_add + { 32'h0, x };
assign partial_sub = { 1'b0, d_in } - { 1'b0, s_in };
assign partial_sub_x = partial_sub - { 32'h0, x };
// overflows
assign av = (d_in[31] & s_in[31] & (!partial_add_x[31])) | ((!d_in[31]) & (!s_in[31]) & partial_add_x[31]);
assign sv = (d_in[31] & (!s_in[31]) & (!partial_sub_x[31])) | ((!d_in[31]) & s_in[31] & partial_sub_x[31]);

assign q_addabs = { 1'b0, d_in } + { 1'b0, s_abs_in };
assign q_subabs = { 1'b0, d_in } - { 1'b0, s_abs_in };

assign flag_uborrow_o = partial_sub[32]; // unsigned borrow used in MOVD, MOVI, MOVS
/*
assign q_o = opcode_in[0] ? partial_sub_x:partial_add_x;
  
assign flag_c_o = opcode_in[0] ? // SUB 
			      opcode_in[2] ? sv:partial_sub_x[32]:
				  opcode_in[2] ? av:partial_add_x[32];
assign q_cmpsub_o = partial_sub[32] ? partial_sub:{ 1'b0, d_in};

*/

always @(*)
	begin
		case (opcode_in)
			`I_ADD: q_o = partial_add[31:0];
			`I_ADDABS: q_o = q_addabs[31:0];
			`I_ADDS,
			`I_ADDSX,
			`I_ADDX: q_o = partial_add_x[31:0];
			`I_CMPSUB: q_o = partial_sub[32] ? d_in:partial_sub[31:0];
			`I_SUB: q_o = partial_sub[31:0];
			`I_SUBABS: q_o = q_subabs[31:0];
			`I_SUBS,
			`I_SUBSX,
			`I_SUBX: q_o = partial_sub_x[31:0];
			`I_WAITCNT: q_o = partial_add[31:0];
			default:
				q_o = partial_add[31:0];
		endcase
	end
	
always @(*)
	begin
		case (opcode_in)
			`I_ADD: flag_c_o = partial_add[32];
			// ADDABS C is complemented unsigned borrow when S<0 or unsigned carry for S>=0
			`I_ADDABS: flag_c_o = s_in[31] ? partial_sub[32]:partial_add[32];
			`I_ADDS: flag_c_o = av;
			`I_ADDSX: flag_c_o = av;
			`I_ADDX: flag_c_o = partial_add_x[32];
			`I_CMPSUB: flag_c_o = !partial_sub[32];
			`I_SUB: flag_c_o = partial_sub_x[32];
			// SUBABS C is complemented unsigned carry when S<0 or unsigned borrow for S>=0
			`I_SUBABS: flag_c_o = s_in[31] ? partial_add[32]:partial_sub[32];
			`I_SUBS: flag_c_o = sv;
			`I_SUBSX: flag_c_o = sv;
			`I_SUBX: flag_c_o = partial_sub_x[32];
			`I_WAITCNT: flag_c_o = partial_add[32];
			default:
				flag_c_o = partial_add[32];
		endcase
	end
endmodule

/* 
 * Compare 2 signed numbers, C flag indicates borrow
 * CMPS & CMPSX
 */
 
module acog_cmpsx(
	input wire [5:0] opcode_in,
	input wire [31:0] s_in,
	input wire [31:0] d_in,
	input wire flag_c_in,
	output wire flag_c_o,
	output wire flag_c_maxs_o,
	output wire [31:0] q_o
	);

wire [31:0] biased_s, biased_d;
wire [32:0] partial_d_minus_s;
wire x;
assign biased_s = { ~s_in[31], s_in[30:0] };
assign biased_d = { ~d_in[31], d_in[30:0] };	
assign partial_d_minus_s = { 1'b0, biased_d } - { 1'b0, biased_s };
assign x = opcode_in[0] & flag_c_in;
assign { flag_c_o, q_o } = partial_d_minus_s - { 32'h0, x };

assign flag_c_maxs_o = partial_d_minus_s[32];

endmodule
// calculates the parity of the input
// odd is asserted when parity is odd

module acog_parity(
	input wire [31:0] q_in,
	output wire odd
	);

wire [15:0] odd16;
wire [7:0] odd8;
wire [3:0] odd4;
wire [2:0] odd2;

assign odd16 =  q_in[31:16] ^  q_in[15:0];
assign odd8  = odd16[15:8]  ^ odd16[7:0];
assign odd4  =  odd8[7:4]   ^  odd8[3:0];
assign odd2  =  odd4[3:2]   ^  odd4[1:0];
assign odd   =  odd2[1]     ^  odd2[0];
endmodule

// reverse and clear to the left
// 31 means 31 cleared bits
//  0 means all reversed bits
module barrel_rev(
	input wire [31:0] d_in,
	input wire [4:0] s_in,
	output wire [31:0] q_o
	);
reg [31:0] rq;
wire [31:0] rev;
assign q_o = rq;
assign rev = {  d_in[ 0], d_in[ 1], d_in[ 2], d_in[ 3], d_in[ 4], d_in[ 5], d_in[ 6], d_in[ 7], 
				d_in[ 8], d_in[ 9], d_in[10], d_in[11], d_in[12], d_in[13], d_in[14], d_in[15], 
				d_in[16], d_in[17], d_in[18], d_in[19], d_in[20], d_in[21], d_in[22], d_in[23], 
				d_in[24], d_in[25], d_in[26], d_in[27], d_in[28], d_in[29], d_in[30], d_in[31] };
always @(rev, s_in)
	begin
		case (s_in)
			5'h00: rq = rev[31:0]; 
			5'h01: rq = {  1'b0, rev[31: 1] };
			5'h02: rq = {  2'b0, rev[31: 2] };
			5'h03: rq = {  3'b0, rev[31: 3] };
			5'h04: rq = {  4'b0, rev[31: 4] };
			5'h05: rq = {  5'b0, rev[31: 5] };
			5'h06: rq = {  6'b0, rev[31: 6] };
			5'h07: rq = {  7'b0, rev[31: 7] };
			5'h08: rq = {  8'b0, rev[31: 8] };
			5'h09: rq = {  9'b0, rev[31: 9] };
			5'h0a: rq = { 10'b0, rev[31:10] };
			5'h0b: rq = { 11'b0, rev[31:11] };
			5'h0c: rq = { 12'b0, rev[31:12] };
			5'h0d: rq = { 13'b0, rev[31:13] };
			5'h0e: rq = { 14'b0, rev[31:14] };
			5'h0f: rq = { 15'b0, rev[31:15] };
			5'h10: rq = { 16'b0, rev[31:16] };
			5'h11: rq = { 17'b0, rev[31:17] };
			5'h12: rq = { 18'b0, rev[31:18] };
			5'h13: rq = { 19'b0, rev[31:19] };
			5'h14: rq = { 20'b0, rev[31:20] };
			5'h15: rq = { 21'b0, rev[31:21] };
			5'h16: rq = { 22'b0, rev[31:22] };
			5'h17: rq = { 23'b0, rev[31:23] };
			5'h18: rq = { 24'b0, rev[31:24] };
			5'h19: rq = { 25'b0, rev[31:25] };
			5'h1a: rq = { 26'b0, rev[31:26] };
			5'h1b: rq = { 27'b0, rev[31:27] };
			5'h1c: rq = { 28'b0, rev[31:28] };
			5'h1d: rq = { 29'b0, rev[31:29] };
			5'h1e: rq = { 30'b0, rev[31:30] };
			5'h1f: rq = { 31'b0, rev[31:31] };
		endcase
	end
endmodule

// rotate c into value from the left
module barrel_rcl(
	input wire [31:0] a,
	input wire flag_c,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift, flag_c)
	begin
		case (shift)
			5'h00: rq = a; 
			5'h01: rq = { a[30:0], flag_c };
			5'h02: rq = { a[29:0], {2{flag_c}} };
			5'h03: rq = { a[28:0], {3{flag_c}} };
			5'h04: rq = { a[27:0], {4{flag_c}} };
			5'h05: rq = { a[26:0], {5{flag_c}} };
			5'h06: rq = { a[25:0], {6{flag_c}} };
			5'h07: rq = { a[24:0], {7{flag_c}} };
			5'h08: rq = { a[23:0], {8{flag_c}} };
			5'h09: rq = { a[22:0], {9{flag_c}} };
			5'h0a: rq = { a[21:0], {10{flag_c}} };
			5'h0b: rq = { a[20:0], {11{flag_c}} };
			5'h0c: rq = { a[19:0], {12{flag_c}} };
			5'h0d: rq = { a[18:0], {13{flag_c}} };
			5'h0e: rq = { a[17:0], {14{flag_c}} };
			5'h0f: rq = { a[16:0], {15{flag_c}} };
			5'h10: rq = { a[15:0], {16{flag_c}} };
			5'h11: rq = { a[14:0], {17{flag_c}} };
			5'h12: rq = { a[13:0], {18{flag_c}} };
			5'h13: rq = { a[12:0], {19{flag_c}} };
			5'h14: rq = { a[11:0], {20{flag_c}} };
			5'h15: rq = { a[10:0], {21{flag_c}} };
			5'h16: rq = { a[ 9:0], {22{flag_c}} };
			5'h17: rq = { a[ 8:0], {23{flag_c}} };
			5'h18: rq = { a[ 7:0], {24{flag_c}} };
			5'h19: rq = { a[ 6:0], {25{flag_c}} };
			5'h1a: rq = { a[ 5:0], {26{flag_c}} };
			5'h1b: rq = { a[ 4:0], {27{flag_c}} };
			5'h1c: rq = { a[ 3:0], {28{flag_c}} };
			5'h1d: rq = { a[ 2:0], {29{flag_c}} };
			5'h1e: rq = { a[ 1:0], {30{flag_c}} };
			5'h1f: rq = { a[ 0:0], {31{flag_c}} };
		endcase
	end
endmodule

// rotate c into value right
module barrel_rcr(
	input wire [31:0] a,
	input wire flag_c,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift, flag_c)
	begin
		case (shift)
			5'h00: rq = a; 
			5'h01: rq = {  {1{flag_c}}, a[31:1] };
			5'h02: rq = {  {2{flag_c}}, a[31:2] };
			5'h03: rq = {  {3{flag_c}}, a[31:3] };
			5'h04: rq = {  {4{flag_c}}, a[31:4] };
			5'h05: rq = {  {5{flag_c}}, a[31:5] };
			5'h06: rq = {  {6{flag_c}}, a[31:6] };
			5'h07: rq = {  {7{flag_c}}, a[31:7] };
			5'h08: rq = {  {8{flag_c}}, a[31:8] };
			5'h09: rq = {  {9{flag_c}}, a[31:9] };
			5'h0a: rq = { {10{flag_c}}, a[31:10] };
			5'h0b: rq = { {11{flag_c}}, a[31:11] };
			5'h0c: rq = { {12{flag_c}}, a[31:12] };
			5'h0d: rq = { {13{flag_c}}, a[31:13] };
			5'h0e: rq = { {14{flag_c}}, a[31:14] };
			5'h0f: rq = { {15{flag_c}}, a[31:15] };
			5'h10: rq = { {16{flag_c}}, a[31:16] };
			5'h11: rq = { {17{flag_c}}, a[31:17] };
			5'h12: rq = { {18{flag_c}}, a[31:18] };
			5'h13: rq = { {19{flag_c}}, a[31:19] };
			5'h14: rq = { {20{flag_c}}, a[31:20] };
			5'h15: rq = { {21{flag_c}}, a[31:21] };
			5'h16: rq = { {22{flag_c}}, a[31:22] };
			5'h17: rq = { {23{flag_c}}, a[31:23] };
			5'h18: rq = { {24{flag_c}}, a[31:24] };
			5'h19: rq = { {25{flag_c}}, a[31:25] };
			5'h1a: rq = { {26{flag_c}}, a[31:26] };
			5'h1b: rq = { {27{flag_c}}, a[31:27] };
			5'h1c: rq = { {28{flag_c}}, a[31:28] };
			5'h1d: rq = { {29{flag_c}}, a[31:29] };
			5'h1e: rq = { {30{flag_c}}, a[31:30] };
			5'h1f: rq = { {31{flag_c}}, a[31:31] };
		endcase              
	end
endmodule

module barrel_rol(
	input wire [31:0] a,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift)
	begin
		case (shift)
			5'h00: rq = a; 
			5'h01: rq = { a[30:0], a[31] };
			5'h02: rq = { a[29:0], a[31:30] };
			5'h03: rq = { a[28:0], a[31:29] };
			5'h04: rq = { a[27:0], a[31:28] };
			5'h05: rq = { a[26:0], a[31:27] };
			5'h06: rq = { a[25:0], a[31:26] };
			5'h07: rq = { a[24:0], a[31:25] };
			5'h08: rq = { a[23:0], a[31:24] };
			5'h09: rq = { a[22:0], a[31:23] };
			5'h0a: rq = { a[21:0], a[31:22] };
			5'h0b: rq = { a[20:0], a[31:21] };
			5'h0c: rq = { a[19:0], a[31:20] };
			5'h0d: rq = { a[18:0], a[31:19] };
			5'h0e: rq = { a[17:0], a[31:18] };
			5'h0f: rq = { a[16:0], a[31:17] };
			5'h10: rq = { a[15:0], a[31:16] };
			5'h11: rq = { a[14:0], a[31:15] };
			5'h12: rq = { a[13:0], a[31:14] };
			5'h13: rq = { a[12:0], a[31:13] };
			5'h14: rq = { a[11:0], a[31:12] };
			5'h15: rq = { a[10:0], a[31:11] };
			5'h16: rq = { a[ 9:0], a[31:10] };
			5'h17: rq = { a[ 8:0], a[31: 9] };
			5'h18: rq = { a[ 7:0], a[31: 8] };
			5'h19: rq = { a[ 6:0], a[31: 7] };
			5'h1a: rq = { a[ 5:0], a[31: 6] };
			5'h1b: rq = { a[ 4:0], a[31: 5] };
			5'h1c: rq = { a[ 3:0], a[31: 4] };
			5'h1d: rq = { a[ 2:0], a[31: 3] };
			5'h1e: rq = { a[ 1:0], a[31: 2] };
			5'h1f: rq = { a[ 0:0], a[31: 1] };
		endcase
	end
endmodule

module barrel_ror(
	input wire [31:0] a,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift)
	begin
		case (shift)
			5'h00: rq = a; 
			5'h01: rq = { a[0], a[31:1] };
			5'h02: rq = { a[ 1:0], a[31:2] };
			5'h03: rq = { a[ 2:0], a[31:3] };
			5'h04: rq = { a[ 3:0], a[31:4] };
			5'h05: rq = { a[ 4:0], a[31:5] };
			5'h06: rq = { a[ 5:0], a[31:6] };
			5'h07: rq = { a[ 6:0], a[31:7] };
			5'h08: rq = { a[ 7:0], a[31:8] };
			5'h09: rq = { a[ 8:0], a[31:9] };
			5'h0a: rq = { a[ 9:0], a[31:10] };
			5'h0b: rq = { a[10:0], a[31:11] };
			5'h0c: rq = { a[11:0], a[31:12] };
			5'h0d: rq = { a[12:0], a[31:13] };
			5'h0e: rq = { a[13:0], a[31:14] };
			5'h0f: rq = { a[14:0], a[31:15] };
			5'h10: rq = { a[15:0], a[31:16] };
			5'h11: rq = { a[16:0], a[31:17] };
			5'h12: rq = { a[17:0], a[31:18] };
			5'h13: rq = { a[18:0], a[31:19] };
			5'h14: rq = { a[19:0], a[31:20] };
			5'h15: rq = { a[20:0], a[31:21] };
			5'h16: rq = { a[21:0], a[31:22] };
			5'h17: rq = { a[22:0], a[31:23] };
			5'h18: rq = { a[23:0], a[31:24] };
			5'h19: rq = { a[24:0], a[31:25] };
			5'h1a: rq = { a[25:0], a[31:26] };
			5'h1b: rq = { a[26:0], a[31:27] };
			5'h1c: rq = { a[27:0], a[31:28] };
			5'h1d: rq = { a[28:0], a[31:29] };
			5'h1e: rq = { a[29:0], a[31:30] };
			5'h1f: rq = { a[30:0], a[31:31] };
		endcase
	end
endmodule

module barrel_shl(
	input wire [31:0] a,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift[4:2])
	begin
		case (shift[4:2])
			3'h0: rq = a; 
			3'h1: rq = { a[27:0], 4'b0 };
			3'h2: rq = { a[23:0], 8'b0 };
			3'h3: rq = { a[19:0], 12'b0 };
			3'h4: rq = { a[15:0], 16'b0 };
			3'h5: rq = { a[11:0], 20'b0 };
			3'h6: rq = { a[ 7:0], 24'b0 };
			3'h7: rq = { a[ 3:0], 28'b0 };
		endcase
	end
endmodule

/*
module barrel_shl(
	input wire [31:0] a,
	output wire [31:0] q,
	input wire [4:0] shift
	);
	
reg [31:0] rq;
assign q = rq;

always @(a, shift)
	begin
		case (shift)
			5'h00: rq = a; 
			5'h01: rq = { a[30:0], 1'b0 };
			5'h02: rq = { a[29:0], 2'b0 };
			5'h03: rq = { a[28:0], 3'b0 };
			5'h04: rq = { a[27:0], 4'b0 };
			5'h05: rq = { a[26:0], 5'b0 };
			5'h06: rq = { a[25:0], 6'b0 };
			5'h07: rq = { a[24:0], 7'b0 };
			5'h08: rq = { a[23:0], 8'b0 };
			5'h09: rq = { a[22:0], 9'b0 };
			5'h0a: rq = { a[21:0], 10'b0 };
			5'h0b: rq = { a[20:0], 11'b0 };
			5'h0c: rq = { a[19:0], 12'b0 };
			5'h0d: rq = { a[18:0], 13'b0 };
			5'h0e: rq = { a[17:0], 14'b0 };
			5'h0f: rq = { a[16:0], 15'b0 };
			5'h10: rq = { a[15:0], 16'b0 };
			5'h11: rq = { a[14:0], 17'b0 };
			5'h12: rq = { a[13:0], 18'b0 };
			5'h13: rq = { a[12:0], 19'b0 };
			5'h14: rq = { a[11:0], 20'b0 };
			5'h15: rq = { a[10:0], 21'b0 };
			5'h16: rq = { a[ 9:0], 22'b0 };
			5'h17: rq = { a[ 8:0], 23'b0 };
			5'h18: rq = { a[ 7:0], 24'b0 };
			5'h19: rq = { a[ 6:0], 25'b0 };
			5'h1a: rq = { a[ 5:0], 26'b0 };
			5'h1b: rq = { a[ 4:0], 27'b0 };
			5'h1c: rq = { a[ 3:0], 28'b0 };
			5'h1d: rq = { a[ 2:0], 29'b0 };
			5'h1e: rq = { a[ 1:0], 30'b0 };
			5'h1f: rq = { a[ 0:0], 31'b0 };
		endcase
	end
endmodule
*/

module barrel_shr(
	input wire [31:0] a,
	output wire [31:0] q_shr,
	output wire [31:0] q_sar,
	input wire [4:0] shift
	);

reg [31:0] rq, mask;
assign q_shr = rq;

assign q_sar = a[31] ? mask | rq:rq;

always @(a, shift)
	begin
		case (shift[4:2])
			3'h0: rq = a; 
			3'h1: rq = {  4'b0, a[31: 4] };
			3'h2: rq = {  8'b0, a[31: 8] };
			3'h3: rq = { 12'b0, a[31:12] };
			3'h4: rq = { 16'b0, a[31:16] };
			3'h5: rq = { 20'b0, a[31:20] };
			3'h6: rq = { 24'b0, a[31:24] };
			3'h7: rq = { 28'b0, a[31:28] };
		endcase
	end
	
always @(shift)
	begin
		case (shift)
			5'h00: mask = 32'h0000_0000; 
			5'h01: mask = 32'h8000_0000;
			5'h02: mask = 32'hc000_0000;
			5'h03: mask = 32'he000_0000;
			5'h04: mask = 32'hf000_0000;
			5'h05: mask = 32'hf800_0000;
			5'h06: mask = 32'hfc00_0000;
			5'h07: mask = 32'hfe00_0000;
			5'h08: mask = 32'hff00_0000;
			5'h09: mask = 32'hff80_0000;
			5'h0a: mask = 32'hffc0_0000;
			5'h0b: mask = 32'hffe0_0000;
			5'h0c: mask = 32'hfff0_0000;
			5'h0d: mask = 32'hfff8_0000;
			5'h0e: mask = 32'hfffc_0000;
			5'h0f: mask = 32'hfffe_0000;
			5'h10: mask = 32'hffff_0000;
			5'h11: mask = 32'hffff_8000;
			5'h12: mask = 32'hffff_c000;
			5'h13: mask = 32'hffff_e000;
			5'h14: mask = 32'hffff_f000;
			5'h15: mask = 32'hffff_f800;
			5'h16: mask = 32'hffff_fc00;
			5'h17: mask = 32'hffff_fe00;
			5'h18: mask = 32'hffff_ff00;
			5'h19: mask = 32'hffff_ff80;
			5'h1a: mask = 32'hffff_ffc0;
			5'h1b: mask = 32'hffff_ffe0;
			5'h1c: mask = 32'hffff_fff0;
			5'h1d: mask = 32'hffff_fff8;
			5'h1e: mask = 32'hffff_fffc;
			5'h1f: mask = 32'hffff_fffe;
		endcase
	end

endmodule
/*
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
