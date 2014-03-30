/* 
 * ACog - Memory
 *
 * Triple ported 32 bit wide memory
 */
`include "acog_defs.v" 
module acog_mem(
	input wire clk_in,
	input wire reset_in,
	input wire [1:0] state_in,
	// fetch channel
	input wire [`MEM_WIDTH-1:0] f_addr_in,
	output wire [31:0] f_data_o,
	// s channel
	input wire [`MEM_WIDTH-1:0] s_addr_in,
	//input wire s_write_in,
	output reg [31:0] s_data_o,
	output reg [31:0] s_data_neg_o,
	// d channel
	input wire [`MEM_WIDTH-1:0] d_addr_in,
	input wire d_write_in,
	input wire [31:0] d_data_in,
	output reg [31:0] d_data_o,
	output reg d_data_is_zero_o,
	output reg d_data_is_one_o,
	output reg [31:0] d_lshift_o,
	output reg [31:0] d_rshift_o,
	// ports
	input wire [31:0] port_a_in,
	output wire [31:0] port_a_o,
	output wire [31:0] port_a_dir_o,
	input wire [31:0] port_b_in,
	output wire [31:0] port_b_o,
	output wire [31:0] port_b_dir_o,
	//
	output wire port_pne_pina_o,
	output wire port_peq_pina_o,
	output wire port_pne_pinb_o,
	output wire port_peq_pinb_o,
	output wire port_cnt_eq_d_o
	
	);

reg [31:0] PAR, CNT, INA, INB, OUTA, OUTB, DIRA, DIRB;

wire [`MEM_WIDTH-1:0] left_addr_mux, muxed_d_addr;
wire [31:0] s_data_from_memory, d_data_from_memory;
reg [31:0] d_mux, s_mux;
reg latched_i; // latched i flag in opcode
reg load_from_mem; // asserted when memory needs to be read (during READ cycle)
reg run_mode; // asserted during load from HUB to COG
reg [`MEM_WIDTH-1:0] latched_source_addr, latched_dest_addr;
assign left_addr_mux = (state_in == `ST_FETCH) ? f_addr_in:s_data_from_memory[8:0]; //s_addr_in;

assign f_data_o = s_data_from_memory;

assign port_a_o = OUTA;
assign port_b_o = OUTB;
assign port_a_dir_o = DIRA;
assign port_b_dir_o = DIRB;

assign port_cnt_eq_d_o = CNT == d_data_o;
assign port_peq_pina_o = d_data_o == (INA & s_data_o);
assign port_pne_pina_o = d_data_o != (INA & s_data_o);
assign port_peq_pinb_o = d_data_o == (INB & s_data_o);
assign port_pne_pinb_o = d_data_o != (INB & s_data_o);

always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				CNT <= 32'h0;
				run_mode <= 1'b0;
				PAR <= 32'b00000000000000_11111000000000_0_000;
			end
		else
			begin
				CNT <= CNT + 32'h1;
				case (state_in)
					`ST_FETCH:
						begin
							INA <= port_a_in;
							INB <= port_b_in;
						end
					`ST_DECODE:
						begin
							latched_i <= s_data_from_memory[`OP_I];
							latched_source_addr <= s_data_from_memory[`MEM_WIDTH-1:0];
							latched_dest_addr <= s_data_from_memory[17:9];
							load_from_mem <= 1'b1; // prevents S&D to be loaded multiple times when in wait instructions
						end
					`ST_READ: // latch values from memory or registers
						begin
							if (load_from_mem)
								begin
									s_data_neg_o <= 32'h0 - s_mux; // used in abs, xxxabs, sumxx
									s_data_o <= s_mux;
									case (s_mux[1:0]) // pre-shift for D
										2'b00: d_lshift_o <= d_mux;
										2'b01: d_lshift_o <= { d_mux[30:0], 1'b0 };
										2'b10: d_lshift_o <= { d_mux[29:0], 2'b0 };
										2'b11: d_lshift_o <= { d_mux[28:0], 3'b0 };
									endcase
									case (s_mux[1:0]) // pre-shift for D
										2'b00: d_rshift_o <= d_mux;
										2'b01: d_rshift_o <= { 1'b0, d_mux[31:1] };
										2'b10: d_rshift_o <= { 2'b0, d_mux[31:2] };
										2'b11: d_rshift_o <= { 3'b0, d_mux[31:3] };
									endcase
									d_data_o <= d_mux;
									d_data_is_zero_o <= d_mux == 32'h0;
									d_data_is_one_o <= d_mux == 32'h0000_0001;
									load_from_mem <= 1'b0; // loaded in this cycle
								end
						end
					`ST_WBACK:
						if (d_write_in)
							begin
								case (d_addr_in)
									`R_OUTA: OUTA <= d_data_in;
									`R_OUTB: OUTB <= d_data_in;
									`R_DIRA:  DIRA <= d_data_in;
									`R_DIRB:  DIRB <= d_data_in;
								endcase
								if (d_addr_in == 9'h1ef) // run mode ends with the write to address 0
									run_mode <= 1'b1;
							end
				endcase
			end
	end

always @(*)
	begin
		if (latched_i)
			s_mux = { 23'h0, latched_source_addr };
		else
			begin
				s_mux = s_data_from_memory;
				case (s_addr_in)
					`R_PAR: if (run_mode) s_mux = { 18'h0, PAR[31:18] }; else s_mux = { 16'h0, PAR[17:4], 2'h0 };
					`R_CNT: if (run_mode) s_mux = CNT;
					`R_INA: if (run_mode) s_mux = INA;
					`R_INB: if (run_mode) s_mux = INB;
					`R_OUTA: if (run_mode) s_mux = OUTA;
					`R_OUTB: if (run_mode) s_mux = OUTB;
					`R_DIRA: if (run_mode) s_mux = DIRA;
					`R_DIRB: if (run_mode) s_mux = DIRB;
				endcase
			end
	end


always @(*)
	begin
		d_mux = d_data_from_memory;
		if (run_mode) 
			case (d_addr_in)
				`R_OUTA: d_mux = OUTA;
				`R_OUTB: d_mux = OUTB;
				`R_DIRA: d_mux = DIRA;
				`R_DIRB: d_mux = DIRB;
			endcase
	end
	
assign muxed_d_addr = (state_in == `ST_WBACK) ? latched_dest_addr:s_data_from_memory[17:9];
wire cog_mem_write;
// Write to memory is only possible
assign cog_mem_write = ((state_in == `ST_WBACK) & d_write_in) &
                       ((run_mode & (latched_dest_addr[8:4] == 5'h1f)) ? 1'b0:1'b1);

`ifdef SIMULATOR
memblock_dp_x32 mem(
	.clk_i(clk_in),
	.port_a_addr_i(left_addr_mux),
	.port_b_addr_i(muxed_d_addr), 
	.port_a_rden_i(1'b1),
	.port_b_rden_i(1'b1),
	.port_a_q_o(s_data_from_memory),
	.port_b_q_o(d_data_from_memory),
	.port_b_wen_i(cog_mem_write),
	.port_b_data_i(d_data_in) );
`else
`ifdef LATTICE_MACHXO2 

cog0_mem mem(
	.DataInA(), 
	.DataInB(d_data_in), 
	.AddressA(left_addr_mux), 
	.AddressB(muxed_d_addr), 
	.ClockA(clk_in), 
	.ClockB(clk_in), 
    .ClockEnA(1'b1), 
	.ClockEnB(1'b1), 
	.WrA(1'b0), 
	.WrB(cog_mem_write), 
	.ResetA(1'b0), 
	.ResetB(1'b0), 
	.QA(s_data_from_memory),
	.QB(d_data_from_memory));
`else //ALTERA_CV
`ifdef ALTERA_CV
cog_mem_altera (
	.address_a(left_addr_mux),
	.address_b(muxed_d_addr),
	.clock(clk_in),
	.data_a(32'b0),
	.data_b(d_data_in),
	.wren_a(1'b0),
	.wren_b(cog_mem_write),
	.q_a(s_data_from_memory),
	.q_b(d_data_from_memory));
`endif
`endif // ifdef LATTICE...
`endif // ifdef SIMULATOR

initial
	begin
		CNT  = 0;
		PAR  = 0;
		OUTA = 0;
		OUTB = 0;
		DIRA = 0;
		DIRB = 0;
		latched_i = 0;
		latched_source_addr = 0;
		latched_dest_addr = 0;
		run_mode = 0;
	end

endmodule


`ifdef SIMULATOR
module memblock_dp_x32(
	input wire clk_i,
	input wire [8:0] port_a_addr_i,
	input wire [8:0] port_b_addr_i,
	input wire port_a_rden_i,
	input wire port_b_rden_i,
	output reg [31:0] port_a_q_o,
	output reg [31:0] port_b_q_o,
	input wire port_b_wen_i,
	input wire [31:0] port_b_data_i
	);

reg [31:0] mem[511:0];

always @(posedge clk_i)
	begin
		if (port_a_rden_i)
			port_a_q_o <= mem[port_a_addr_i];
		if (port_b_rden_i)
			port_b_q_o <= mem[port_b_addr_i];
		if (port_b_wen_i)
			mem[port_b_addr_i] <= port_b_data_i;
	end

integer i;
initial
	begin
		for ( i = 32'd0; i < 32'd511; i = i + 32'd1)
			mem[i] = { i[15:0], i[15:0] };//32'hDEADBEEF;
		#0
		// HUB loader
		mem[9'h1f4] = { `I_MOV,    4'b0010, 4'hf, 9'h1f1, `R_PAR}; //  mov    $1f1, PAR     ' load src ptr
		mem[9'h1f5] = { `I_MOV,    4'b0011, 4'hf, 9'h1f2, 9'h000}; //  mov    $1f2, #0      ' load src ptr
		mem[9'h1f6] = { `I_MOV,    4'b0011, 4'hf, 9'h1f3, 9'h1f0}; //  mov    $1f3, #1f0    ' load counter
		mem[9'h1f7] = { `I_MOVD,   4'b0010, 4'hf, 9'h1f8, 9'h1f2}; //  loop movd   $1fa, $1f2    ' dest ptr
		mem[9'h1f8] = { `I_RDLONG, 4'b0010, 4'hf, 9'h000, 9'h1f1}; //  rdlong $0-0, $1f1    ' load long
		mem[9'h1f9] = { `I_ADD,    4'b0011, 4'hf, 9'h1f1, 9'h004}; //  add    $1f1, #$4     ' icr dest addr
		mem[9'h1fa] = { `I_ADD,    4'b0011, 4'hf, 9'h1f2, 9'h001}; //  add    $1f2, #$1     ' icr dest addr
		mem[9'h1fb] = { `I_DJNZ,   4'b0011, 4'hf, 9'h1f3, 9'h1f7}; //  djnz   $1f3, loop
		mem[9'h1fc] = { `I_JMP,    4'b0001, 4'hf,  9'h00, 9'h000}; //  jmp    #$0           ' jump to start
/*		
		mem[9'h000] = { `I_RDBYTE, 4'b0001, 4'hf, 9'h020, 9'h00}; // 00000000  5927ff5c  		mov $004, #3
		mem[9'h001] = { `I_RDBYTE, 4'b0011, 4'hf, 9'h021, 9'h00}; // 00000004  35a9fe5c  		nop
		mem[9'h002] = { `I_RDBYTE, 4'b0001, 4'hf, 9'h020, 9'h01}; // 00000004  35a9fe5c  		nop
		mem[9'h003] = { `I_RDBYTE, 4'b0011, 4'hf, 9'h021, 9'h01}; // 00000000  5927ff5c  		mov $004, #3
		mem[9'h004] = { `I_RDBYTE, 4'b0001, 4'hf, 9'h020, 9'h02}; // 00000004  35a9fe5c  		nop
		mem[9'h005] = { `I_RDBYTE, 4'b0011, 4'hf, 9'h021, 9'h02}; // 00000004  35a9fe5c  		nop
		mem[9'h006] = { `I_RDBYTE, 4'b0001, 4'hf, 9'h020, 9'h03}; // 00000000  5927ff5c  		mov $004, #3
		mem[9'h007] = { `I_RDBYTE, 4'b0011, 4'hf, 9'h021, 9'h03}; // 00000004  35a9fe5c  		nop
		mem[9'h008] = { `I_RDWORD, 4'b0001, 4'hf, 9'h020, 9'h00}; // 00000004  35a9fe5c  		nop
		mem[9'h009] = { `I_RDWORD, 4'b0011, 4'hf, 9'h021, 9'h00}; // 00000004  35a9fe5c  		nop
		mem[9'h00a] = { `I_RDWORD, 4'b0001, 4'hf, 9'h020, 9'h02}; // 00000004  35a9fe5c  		nop
		mem[9'h00b] = { `I_RDWORD, 4'b0011, 4'hf, 9'h021, 9'h02}; // 00000004  35a9fe5c  		nop
		mem[9'h00c] = { `I_RDLONG, 4'b0001, 4'hf, 9'h020, 9'h00}; // 00000004  35a9fe5c  		nop
		mem[9'h00d] = { `I_RDLONG, 4'b0011, 4'hf, 9'h021, 9'h00}; // 00000000  5927ff5c  		mov $004, #3
		mem[9'h00e] = { `I_JMP,    4'b0001, 4'hf,  9'h00, 9'h0e}; // 00000004  35a9fe5c  		jmp #003
		mem[9'h020] = 32'h76543210;
*/
		//               op                  dest       src
		//                     ZCRI CCCC 184268421 184218421
		//$readmemh("bcd.hex", mem);
		
		//mem[9'h000] = { `I_MOV, 4'b0011, 4'hf, `R_DIRA, 9'h01}; // 00000000  5927ff5c  		mov $004, #3
		//mem[9'h001] = { `I_MOV, 4'b0011, 4'hf, `R_OUTA, 9'h01}; // 00000004  35a9fe5c  		nop
		///mem[9'h002] = { `I_MOV, 4'b0011, 4'hf, `R_OUTA, 9'h00}; // 00000004  35a9fe5c  		nop
		//mem[9'h003] = { `I_JMP, 4'b0001, 4'hf,   9'h00, 9'h01}; // 00000004  35a9fe5c  		jmp #003
		
/*		
		mem[9'h000] = 32'b010111_0011_1111_110010011_101011001; // 00000000  5927ff5c  		call	#BCDSQR15
		mem[9'h001] = 32'b010111_0001_1111_000000000_000000001; // 00000004  35a9fe5c  		jmp #* call	#TOASCIIQDR
		mem[9'h002] = 32'b010111_0011_1111_100011111_100010000; // 00000008  103ffe5c  		call	#RTOINT
		mem[9'h003] = 32'b011011_0010_1111_110111001_111001011; // 0000000c  cb73bf6c  BCDSUB15		xor	rBSgn,cnt_SMASK	' I love long routines ;-)
		mem[9'h004] = 32'b101000_0010_1111_110111110_110110101; // 00000010  b57dbfa0  BCDADD15		mov	rt1,rASgn
		mem[9'h005] = 32'b011011_0010_1111_110111110_110111001; // 00000014  b97dbf6c  		xor	rt1,rBSgn
		mem[9'h006] = 32'b011000_1000_1111_110111110_111001011; // 00000018  cb7d3f62  		test	rt1,cnt_SMASK wz
		mem[9'h007] = 32'b010111_0001_0101_000000000_000100001; // 0000001c  2100545c  	if_nz	jmp	#SUB15
		mem[9'h008] = 32'b101000_0010_1111_110111110_110110100; // 00000020  b47dbfa0  ADD15		mov	rt1,rAExp
		mem[9'h009] = 32'b110101_1010_1111_110111110_110111000; // 00000024  b87dbfd6  		subs	rt1,rBExp wz
		mem[9'h00a] = 32'b101010_0010_1111_110111111_110111110; // 00000028  be7fbfa8  		abs	rt2,rt1
		mem[9'h00b] = 32'b010111_0001_1010_000000000_000011001; // 0000002c  1900685c  	if_z	jmp	#ADD15_20		' adds, no shift
		mem[9'h00c] = 32'b100001_0101_1111_110111110_000010000; // 00000030  107c7f85  		cmp	rt1,#16 wc
		mem[9'h00d] = 32'b010111_0001_1100_000000000_000010100; // 00000034  1400705c  	if_c	jmp	#ADD15_5		' shifts B
		mem[9'h00e] = 32'b100001_0101_1111_110111111_000010000; // 00000038  107e7f85  		cmp	rt2,#16 wc
		mem[9'h00f] = 32'b010111_0001_1100_000000000_000010111; // 0000003c  1700705c  	if_c	jmp	#ADD15_10
		mem[9'h010] = 32'b100001_0101_1111_110111110_000010000; // 00000040  107c7f85  		cmp	rt1,#16 wc
		mem[9'h011] = 32'b010111_0011_1100_011100100_011100000; // 00000044  e0c8f15c  	if_c	call	#LOADBTOR
		mem[9'h012] = 32'b010111_0011_0011_011011111_011011011; // 00000048  dbbecd5c  	if_nc	call	#LOADATOR
		mem[9'h013] = 32'b010111_0001_1111_000000000_000111110; // 0000004c  3e007c5c  		jmp	#ADD15_ret
		mem[9'h014] = 32'b010111_0011_1111_010110110_010110001; // 00000050  b16cfd5c  ADD15_5		call	#mSHRB15
		mem[9'h015] = 32'b111001_0011_1111_110111111_000010100; // 00000054  147effe4  		djnz	rt2,#ADD15_5
		mem[9'h016] = 32'b010111_0001_1111_000000000_000011001; // 00000058  19007c5c  		jmp	#ADD15_20
		mem[9'h017] = 32'b010111_0011_1111_010101011_010100111; // 0000005c  a756fd5c  ADD15_10		call	#mSHRA15
		mem[9'h018] = 32'b111001_0011_1111_110111111_000010111; // 00000060  177effe4  		djnz	rt2,#ADD15_10
		mem[9'h019] = 32'b010111_0011_1111_001110000_001101000; // 00000064  68e0fc5c  ADD15_20		call	#mADD15
		mem[9'h01a] = 32'b101000_0010_1111_110111110_110111010; // 00000068  ba7dbfa0  		mov	rt1,rR
		mem[9'h01b] = 32'b011000_1010_1111_110111110_111001100; // 0000006c  cc7dbf62  		and	rt1,cnt_MSD wz
		mem[9'h01c] = 32'b010111_0011_0101_011000001_010111100; // 00000070  bc82d55c  	if_nz	call	#mSHRR15
		mem[9'h01d] = 32'b101000_0010_1111_110111100_110110100; // 00000074  b479bfa0  		mov	rRExp,rAExp
		mem[9'h01e] = 32'b100000_0011_0101_110111100_000000001; // 00000078  0178d780  	if_nz	add	rRExp,#1
		mem[9'h01f] = 32'b101000_0010_1111_110111101_110110101; // 0000007c  b57bbfa0  		mov	rRSgn,rASgn	' sets sign from A
		mem[9'h020] = 32'b010111_0001_1111_000000000_000111110; // 00000080  3e007c5c  		jmp	#ADD15_ret
		mem[9'h021] = 32'b101000_0010_1111_110111110_110110100; // 00000084  b47dbfa0  SUB15		mov	rt1,rAExp
		mem[9'h022] = 32'b110101_1010_1111_110111110_110111000; // 00000088  b87dbfd6  		subs	rt1,rBExp wz
		mem[9'h023] = 32'b101010_0010_1111_110111111_110111110; // 0000008c  be7fbfa8  		abs	rt2,rt1
		mem[9'h024] = 32'b010111_0001_1010_000000000_000110001; // 00000090  3100685c  	if_z	jmp	#SUB15_15	' adds, no shift
		mem[9'h025] = 32'b100001_0101_1111_110111110_000010000; // 00000094  107c7f85  		cmp	rt1,#16 wc
		mem[9'h026] = 32'b010111_0001_1100_000000000_000101110; // 00000098  2e00705c  	if_c	jmp	#SUB15_10	' shifts B
		mem[9'h027] = 32'b100001_0101_1111_110111111_000010000; // 0000009c  107e7f85  		cmp	rt2,#16 wc
		mem[9'h028] = 32'b010111_0001_1100_000000000_000101101; // 000000a0  2d00705c  	if_c	jmp	#SUB15_5
		mem[9'h029] = 32'b100001_0101_1111_110111110_000010000; // 000000a4  107c7f85  		cmp	rt1,#16 wc
		mem[9'h02a] = 32'b010111_0011_1100_011100100_011100000; // 000000a8  e0c8f15c  	if_c	call	#LOADBTOR
		mem[9'h02b] = 32'b010111_0011_0011_011011111_011011011; // 000000ac  dbbecd5c  	if_nc	call	#LOADATOR
		mem[9'h02c] = 32'b010111_0001_1111_000000000_000111110; // 000000b0  3e007c5c  		jmp	#SUB15_ret
		mem[9'h02d] = 32'b010111_0011_1111_011011010_011001110; // 000000b4  ceb4fd5c  SUB15_5		call	#XCHGAB
		mem[9'h02e] = 32'b010111_0011_1111_010110110_010110001; // 000000b8  b16cfd5c  SUB15_10		call	#mSHRB15
		mem[9'h02f] = 32'b111001_0011_1111_110111111_000101110; // 000000bc  2e7effe4  		djnz	rt2,#SUB15_10
		mem[9'h030] = 32'b010111_0001_1111_000000000_000110011; // 000000c0  33007c5c  		jmp	#SUB15_20
		mem[9'h031] = 32'b010111_0011_1111_011001010_011001000; // 000000c4  c894fd5c  SUB15_15		call	#mCMP15
		mem[9'h032] = 32'b010111_0011_1100_011011010_011001110; // 000000c8  ceb4f15c  	if_c	call	#XCHGAB		' sig(A)<sig(B)
		mem[9'h033] = 32'b101000_0010_1111_110111101_110110101; // 000000cc  b57bbfa0  		mov	rRSgn,rASgn	' transfers sign
		mem[9'h034] = 32'b101000_0010_1111_110111100_110110100; // 000000d0  b479bfa0  		mov	rRExp,rAExp
		mem[9'h035] = 32'b010111_0011_1111_001111001_001110001; // 000000d4  71f2fc5c  		call	#mSUB15
		mem[9'h036] = 32'b101000_0010_1111_110111110_110111010; // 000000d8  ba7dbfa0  SUB15_25		mov	rt1,rR
		mem[9'h037] = 32'b011000_1010_1111_110111110_111001101; // 000000dc  cd7dbf62  		and	rt1,cnt_D12 wz
		mem[9'h038] = 32'b010111_0001_0101_000000000_000111110; // 000000e0  3e00545c  	if_nz	jmp	#SUB15_ret
		mem[9'h039] = 32'b100001_0011_1111_110111100_000000001; // 000000e4  0178ff84  	  	sub	rRExp,#1
		mem[9'h03a] = 32'b010111_0011_1111_010111011_010110111; // 000000e8  b776fd5c    		call	#mSHLR15
		mem[9'h03b] = 32'b010111_0011_1111_011001101_011001011; // 000000ec  cb9afd5c  		call	#mCMPRZ	' tests for zero
		mem[9'h03c] = 32'b010111_0001_0101_000000000_000110110; // 000000f0  3600545c  	if_nz	jmp	#SUB15_25
		mem[9'h03d] = 32'b010111_0011_1111_011101001_011100101; // 000000f4  e5d2fd5c  		call	#LOADZTOR
		mem[9'h03e] = 32'b010111_0001_1111_000000000_000000000; // 000000f8  00007c5c  SUB15_ret	ret
		mem[9'h03f] = 32'b101000_0010_1111_110111100_110110100; // 000000fc  b479bfa0  BCDMUL15		mov	rRExp,rAExp
		mem[9'h040] = 32'b110100_0010_1111_110111100_110111000; // 00000100  b879bfd0  		adds	rRExp,rBExp
		mem[9'h041] = 32'b101000_0011_1111_110111010_000000000; // 00000104  0074ffa0  		mov	rR,#0		' result significand
		mem[9'h042] = 32'b101000_0011_1111_110111011_000000000; // 00000108  0076ffa0  		mov	rR1,#0
		mem[9'h043] = 32'b011000_1000_1111_110110111_110110111; // 0000010c  b76f3f62  		test	rB1,rB1 wz
		mem[9'h044] = 32'b010111_0001_1010_000000000_001000110; // 00000110  4600685c  	if_z	jmp	#MUL15_5 	' avoids 8 zeroes
		mem[9'h045] = 32'b010111_0011_1111_001100111_001010000; // 00000114  50cefc5c  		call	#mMUL8
		mem[9'h046] = 32'b101000_0010_1111_110110111_110110110; // 00000118  b66fbfa0  MUL15_5		mov	rB1,rB
		mem[9'h047] = 32'b010111_0011_1111_001100111_001010000; // 0000011c  50cefc5c  		call	#mMUL8
		mem[9'h048] = 32'b010111_0011_1111_010111011_010110111; // 00000120  b776fd5c  		call	#mSHLR15
		mem[9'h049] = 32'b101000_0010_1111_110111110_110111010; // 00000124  ba7dbfa0  		mov	rt1,rR
		mem[9'h04a] = 32'b011000_1010_1111_110111110_111001101; // 00000128  cd7dbf62  		and	rt1,cnt_D12 wz
		mem[9'h04b] = 32'b100000_0011_0101_110111100_000000001; // 0000012c  0178d780  	if_nz	add	rRExp,#1		' increments exponent
		mem[9'h04c] = 32'b010111_0011_1010_010111011_010110111; // 00000130  b776e95c  	if_z	call	#mSHLR15		' normalizes significand
		mem[9'h04d] = 32'b101000_0010_1111_110111101_110110101; // 00000134  b57bbfa0  		mov	rRSgn,rASgn
		mem[9'h04e] = 32'b011011_0010_1111_110111101_110111001; // 00000138  b97bbf6c  		xor	rRSgn,rBSgn
		mem[9'h04f] = 32'b010111_0001_1111_000000000_000000000; // 0000013c  00007c5c  BCDMUL15_ret	ret
		mem[9'h050] = 32'b101000_0011_1111_111000100_000001000; // 00000140  0888ffa0  mMUL8		mov	rt7,#8
		mem[9'h051] = 32'b101000_0010_1111_111000111_110110111; // 00000144  b78fbfa0  mMUL8_5		mov	rcnt1,rB1
		mem[9'h052] = 32'b011000_1011_1111_111000111_000001111; // 00000148  0f8eff62  		and	rcnt1,#$f wz
		mem[9'h053] = 32'b101000_0011_1111_111000011_000000000; // 0000014c  0086ffa0  		mov	rt6,#0
		mem[9'h054] = 32'b010111_0001_1010_000000000_001011111; // 00000150  5f00685c  	if_z	jmp	#mMUL8_15
		mem[9'h055] = 32'b101000_0010_1111_110111110_110110011; // 00000154  b37dbfa0  mMUL8_10		mov	rt1,rA1
		mem[9'h056] = 32'b101000_0010_1111_110111111_110111011; // 00000158  bb7fbfa0  		mov	rt2,rR1
		mem[9'h057] = 32'b010111_0011_1111_010001111_001111010; // 0000015c  7a1efd5c  		call	#mADD8
		mem[9'h058] = 32'b101000_0010_1111_110111011_111000010; // 00000160  c277bfa0  		mov	rR1,rt5
		mem[9'h059] = 32'b101000_0010_1111_110111110_110110010; // 00000164  b27dbfa0  		mov	rt1,rA
		mem[9'h05a] = 32'b101000_0010_1111_110111111_110111010; // 00000168  ba7fbfa0  		mov	rt2,rR
		mem[9'h05b] = 32'b010111_0011_1111_010001111_001111100; // 0000016c  7c1efd5c  		call	#mADD8C
		mem[9'h05c] = 32'b101000_0010_1111_110111010_111000010; // 00000170  c275bfa0  		mov	rR,rt5
		mem[9'h05d] = 32'b100000_0011_0011_111000011_000000001; // 00000174  0186cf80  	if_nc	add	rt6,#1		' carry counter
		mem[9'h05e] = 32'b111001_0011_1111_111000111_001010101; // 00000178  558effe4  		djnz	rcnt1,#mMUL8_10
		mem[9'h05f] = 32'b101000_0011_1111_111000010_000000100; // 0000017c  0484ffa0  mMUL8_15		mov	rt5,#4
		mem[9'h060] = 32'b001010_0111_1111_110111010_000000001; // 00000180  0174ff29  mMUL8_20		shr	rR,#1 wc
		mem[9'h061] = 32'b001100_0011_1111_110111011_000000001; // 00000184  0176ff30  		rcr	rR1,#1
		mem[9'h062] = 32'b111001_0011_1111_111000010_001100000; // 00000188  6084ffe4  		djnz	rt5,#mMUL8_20
		mem[9'h063] = 32'b001000_0011_1111_111000011_000000100; // 0000018c  0486ff20  		ror	rt6,#4		' convert to MSD
		mem[9'h064] = 32'b011010_0010_1111_110111010_111000011; // 00000190  c375bf68  		or	rR,rt6		' sets new carry digit
		mem[9'h065] = 32'b001010_0011_1111_110110111_000000100; // 00000194  046eff28  		shr	rB1,#4
		mem[9'h066] = 32'b111001_0011_1111_111000100_001010001; // 00000198  5188ffe4  		djnz	rt7,#mMUL8_5
		mem[9'h067] = 32'b010111_0001_1111_000000000_000000000; // 0000019c  00007c5c  mMUL8_ret	ret
		mem[9'h068] = 32'b101000_0010_1111_110111110_110110011; // 000001a0  b37dbfa0  mADD15		mov	rt1,rA1
		mem[9'h069] = 32'b101000_0010_1111_110111111_110110111; // 000001a4  b77fbfa0  		mov	rt2,rB1
		mem[9'h06a] = 32'b010111_0011_1111_010001111_001111010; // 000001a8  7a1efd5c  		call	#mADD8
		mem[9'h06b] = 32'b101000_0010_1111_110111011_111000010; // 000001ac  c277bfa0  		mov	rR1,rt5
		mem[9'h06c] = 32'b101000_0010_1111_110111110_110110010; // 000001b0  b27dbfa0  		mov	rt1,rA
		mem[9'h06d] = 32'b101000_0010_1111_110111111_110110110; // 000001b4  b67fbfa0  		mov	rt2,rB
		mem[9'h06e] = 32'b010111_0011_1111_010001111_001111100; // 000001b8  7c1efd5c  		call	#mADD8C
		mem[9'h06f] = 32'b101000_0010_1111_110111010_111000010; // 000001bc  c275bfa0  		mov	rR,rt5
		mem[9'h070] = 32'b010111_0001_1111_000000000_000000000; // 000001c0  00007c5c  mADD15_ret	ret
		mem[9'h071] = 32'b101000_0010_1111_110111110_110110011; // 000001c4  b37dbfa0  mSUB15		mov	rt1,rA1
		mem[9'h072] = 32'b101000_0010_1111_110111111_110110111; // 000001c8  b77fbfa0  		mov	rt2,rB1
		mem[9'h073] = 32'b010111_0011_1111_010100000_010010000; // 000001cc  9040fd5c  		call	#mSUB8
		mem[9'h074] = 32'b101000_0010_1111_110111011_111000010; // 000001d0  c277bfa0  		mov	rR1,rt5
		mem[9'h075] = 32'b101000_0010_1111_110111110_110110010; // 000001d4  b27dbfa0  		mov	rt1,rA
		mem[9'h076] = 32'b101000_0010_1111_110111111_110110110; // 000001d8  b67fbfa0  		mov	rt2,rB
		mem[9'h077] = 32'b010111_0011_1111_010100000_010010001; // 000001dc  9140fd5c  		call	#mSUB8C
		mem[9'h078] = 32'b101000_0010_1111_110111010_111000010; // 000001e0  c275bfa0  		mov	rR,rt5
		mem[9'h079] = 32'b010111_0001_1111_000000000_000000000; // 000001e4  00007c5c  mSUB15_ret	ret
		mem[9'h07a] = 32'b101000_0011_1111_111000110_000000011; // 000001e8  038cffa0  mADD8		mov	rcarry,#3
		mem[9'h07b] = 32'b001010_0111_1111_111000110_000000001; // 000001ec  018cff29  		shr	rcarry,#1 wc ' sets carry flag
		mem[9'h07c] = 32'b101000_0011_1111_111001000_000001111; // 000001f0  0f90ffa0  mADD8C		mov	rmsk1,#$f
		mem[9'h07d] = 32'b101000_0011_1111_111000010_000000000; // 000001f4  0084ffa0  		mov	rt5,#0
		mem[9'h07e] = 32'b101000_0011_1111_111001001_000001010; // 000001f8  0a92ffa0  		mov	rsh1,#10
		mem[9'h07f] = 32'b101000_0010_1111_111000000_110111110; // 000001fc  be81bfa0  mADD8_1		mov	rt3,rt1
		mem[9'h080] = 32'b011000_0010_1111_111000000_111001000; // 00000200  c881bf60  		and	rt3,rmsk1
		mem[9'h081] = 32'b101000_0010_1111_111000001_110111111; // 00000204  bf83bfa0  		mov	rt4,rt2
		mem[9'h082] = 32'b011000_0010_1111_111000001_111001000; // 00000208  c883bf60  		and	rt4,rmsk1
		mem[9'h083] = 32'b100000_0010_0011_111000001_111000110; // 0000020c  c6838f80  	if_nc	add	rt4,rcarry
		mem[9'h084] = 32'b100000_0110_1111_111000000_111000001; // 00000210  c181bf81  		add	rt3,rt4 wc
		mem[9'h085] = 32'b010111_0001_0011_000000000_010001000; // 00000214  88004c5c  	if_nc	jmp	#mADD8_5
		mem[9'h086] = 32'b101000_0111_1111_111000110_000000001; // 00000218  018cffa1  		mov	rcarry,#1 wc ' clears carry flag for next round
		mem[9'h087] = 32'b010111_0001_1111_000000000_010001111; // 0000021c  8f007c5c  		jmp	#mADD8_ret
		mem[9'h088] = 32'b100001_0100_1111_111000000_111001001; // 00000220  c9813f85  mADD8_5		cmp	rt3,rsh1 wc
		mem[9'h089] = 32'b100001_0010_0011_111000000_111001001; // 00000224  c9818f84  	if_nc	sub	rt3,rsh1
		mem[9'h08a] = 32'b011010_0010_1111_111000010_111000000; // 00000228  c085bf68  	  	or	rt5,rt3
		mem[9'h08b] = 32'b001001_0011_1111_111000110_000000100; // 0000022c  048cff24  		rol	rcarry,#4 ' magic
		mem[9'h08c] = 32'b001011_0011_1111_111001001_000000100; // 00000230  0492ff2c  		shl	rsh1,#4
		mem[9'h08d] = 32'b001011_1011_1111_111001000_000000100; // 00000234  0490ff2e  		shl	rmsk1,#4 wz
		mem[9'h08e] = 32'b010111_0001_0101_000000000_001111111; // 00000238  7f00545c  	if_nz	jmp	#mADD8_1
		mem[9'h08f] = 32'b010111_0001_1111_000000000_000000000; // 0000023c  00007c5c  mADD8_ret	ret
		mem[9'h090] = 32'b101000_0111_1111_111000110_000000001; // 00000240  018cffa1  mSUB8		mov	rcarry,#1 wc ' clrs carry flag
		mem[9'h091] = 32'b101000_0011_1111_111001000_000001111; // 00000244  0f90ffa0  mSUB8C		mov	rmsk1,#$f
		mem[9'h092] = 32'b101000_0011_1111_111000010_000000000; // 00000248  0084ffa0  		mov	rt5,#0
		mem[9'h093] = 32'b101000_0011_1111_111001001_000001010; // 0000024c  0a92ffa0  		mov	rsh1,#10
		mem[9'h094] = 32'b101000_0010_1111_111000000_110111110; // 00000250  be81bfa0  mSUB8_1		mov	rt3,rt1
		mem[9'h095] = 32'b011000_0010_1111_111000000_111001000; // 00000254  c881bf60  		and	rt3,rmsk1
		mem[9'h096] = 32'b101000_0010_1111_111000001_110111111; // 00000258  bf83bfa0  		mov	rt4,rt2
		mem[9'h097] = 32'b011000_0010_1111_111000001_111001000; // 0000025c  c883bf60  		and	rt4,rmsk1
		mem[9'h098] = 32'b100000_0010_1100_111000001_111000110; // 00000260  c683b380  	if_c	add	rt4,rcarry
		mem[9'h099] = 32'b100001_0110_1111_111000000_111000001; // 00000264  c181bf85  		sub	rt3,rt4 wc
		mem[9'h09a] = 32'b100000_0010_1100_111000000_111001001; // 00000268  c981b380  	if_c	add	rt3,rsh1
		mem[9'h09b] = 32'b011010_0010_1111_111000010_111000000; // 0000026c  c085bf68    		or	rt5,rt3
		mem[9'h09c] = 32'b001001_0011_1111_111000110_000000100; // 00000270  048cff24  		rol	rcarry,#4 ' magic
		mem[9'h09d] = 32'b001011_0011_1111_111001001_000000100; // 00000274  0492ff2c  		shl	rsh1,#4
		mem[9'h09e] = 32'b001011_1011_1111_111001000_000000100; // 00000278  0490ff2e  		shl	rmsk1,#4 wz
		mem[9'h09f] = 32'b010111_0001_0101_000000000_010010100; // 0000027c  9400545c  	if_nz	jmp	#mSUB8_1
		mem[9'h0a0] = 32'b010111_0001_1111_000000000_000000000; // 00000280  00007c5c  mSUB8_ret	ret
		mem[9'h0a1] = 32'b101000_0010_1111_111000010_110110011; // 00000284  b385bfa0  mSHLA15         mov     rt5,rA1
		mem[9'h0a2] = 32'b001011_0011_1111_110110011_000000100; // 00000288  0466ff2c                  shl     rA1,#4
		mem[9'h0a3] = 32'b001011_0011_1111_110110010_000000100; // 0000028c  0464ff2c                  shl     rA,#4
		mem[9'h0a4] = 32'b001010_0011_1111_111000010_000011100; // 00000290  1c84ff28                  shr     rt5,#28
		mem[9'h0a5] = 32'b011010_0010_1111_110110010_111000010; // 00000294  c265bf68                  or      rA,rt5
		mem[9'h0a6] = 32'b010111_0001_1111_000000000_000000000; // 00000298  00007c5c  mSHLA15_ret     ret
		mem[9'h0a7] = 32'b101000_0011_1111_111000010_000000100; // 0000029c  0484ffa0  mSHRA15		mov	rt5,#4
		mem[9'h0a8] = 32'b001010_0111_1111_110110010_000000001; // 000002a0  0164ff29  mSHRA15_1	shr	rA,#1 wc
		mem[9'h0a9] = 32'b001100_0011_1111_110110011_000000001; // 000002a4  0166ff30  		rcr	rA1,#1
		mem[9'h0aa] = 32'b111001_0011_1111_111000010_010101000; // 000002a8  a884ffe4  		djnz	rt5,#mSHRA15_1
		mem[9'h0ab] = 32'b010111_0001_1111_000000000_000000000; // 000002ac  00007c5c  mSHRA15_ret	ret
		mem[9'h0ac] = 32'b101000_0011_1111_111000010_000000100; // 000002b0  0484ffa0  mSHLB15		mov	rt5,#4
		mem[9'h0ad] = 32'b001011_0111_1111_110110111_000000001; // 000002b4  016eff2d  mSHLB15_1	shl      rB1,#1 wc
		mem[9'h0ae] = 32'b001101_0011_1111_110110110_000000001; // 000002b8  016cff34  		rcl	rB,#1
		mem[9'h0af] = 32'b111001_0011_1111_111000010_010101101; // 000002bc  ad84ffe4  		djnz	rt5,#mSHLB15_1
		mem[9'h0b0] = 32'b010111_0001_1111_000000000_000000000; // 000002c0  00007c5c  mSHLB15_ret	ret
		mem[9'h0b1] = 32'b101000_0010_1111_111000010_110110110; // 000002c4  b685bfa0  mSHRB15		mov	rt5,rB
		mem[9'h0b2] = 32'b001010_0011_1111_110110110_000000100; // 000002c8  046cff28  		shr	rB,#4
		mem[9'h0b3] = 32'b001011_0011_1111_111000010_000011100; // 000002cc  1c84ff2c  		shl	rt5,#28
		mem[9'h0b4] = 32'b001010_0011_1111_110110111_000000100; // 000002d0  046eff28  		shr	rB1,#4
		mem[9'h0b5] = 32'b011010_0010_1111_110110111_111000010; // 000002d4  c26fbf68  		or	rB1,rt5
		mem[9'h0b6] = 32'b010111_0001_1111_000000000_000000000; // 000002d8  00007c5c  mSHRB15_ret	ret
		mem[9'h0b7] = 32'b101000_0011_1111_111000010_000000100; // 000002dc  0484ffa0  mSHLR15		mov	rt5,#4
		mem[9'h0b8] = 32'b001011_0111_1111_110111011_000000001; // 000002e0  0176ff2d  mSHLR15_1	shl      rR1,#1 wc
		mem[9'h0b9] = 32'b001101_0011_1111_110111010_000000001; // 000002e4  0174ff34  		rcl	rR,#1
		mem[9'h0ba] = 32'b111001_0011_1111_111000010_010111000; // 000002e8  b884ffe4  		djnz	rt5,#mSHLR15_1
		mem[9'h0bb] = 32'b010111_0001_1111_000000000_000000000; // 000002ec  00007c5c  mSHLR15_ret	ret
		mem[9'h0bc] = 32'b101000_0010_1111_111000010_110111010; // 000002f0  ba85bfa0  mSHRR15		mov	rt5,rR
		mem[9'h0bd] = 32'b001010_0011_1111_110111010_000000100; // 000002f4  0474ff28  		shr	rR,#4
		mem[9'h0be] = 32'b001011_0011_1111_111000010_000011100; // 000002f8  1c84ff2c  		shl	rt5,#28
		mem[9'h0bf] = 32'b001010_0011_1111_110111011_000000100; // 000002fc  0476ff28  		shr	rR1,#4
		mem[9'h0c0] = 32'b011010_0010_1111_110111011_111000010; // 00000300  c277bf68  		or	rR1,rt5
		mem[9'h0c1] = 32'b010111_0001_1111_000000000_000000000; // 00000304  00007c5c  mSHRR15_ret	ret
		mem[9'h0c2] = 32'b101000_0010_1111_111000010_111000011; // 00000308  c385bfa0  mSHR6715        mov    rt5,rt6
		mem[9'h0c3] = 32'b001010_0011_1111_111000011_000000100; // 0000030c  0486ff28                  shr    rt6,#4
		mem[9'h0c4] = 32'b001011_0011_1111_111000010_000011100; // 00000310  1c84ff2c                  shl    rt5,#28
		mem[9'h0c5] = 32'b001010_0011_1111_111000100_000000100; // 00000314  0488ff28                  shr    rt7,#4
		mem[9'h0c6] = 32'b011010_0010_1111_111000100_111000010; // 00000318  c289bf68                  or     rt7,rt5
		mem[9'h0c7] = 32'b010111_0001_1111_000000000_000000000; // 0000031c  00007c5c  mSHR6715_ret    ret
		mem[9'h0c8] = 32'b100001_1100_1111_110110010_110110110; // 00000320  b6653f87  mCMP15		cmp	rA,rB wc wz
		mem[9'h0c9] = 32'b100001_1100_1010_110110011_110110111; // 00000324  b7672b87  	if_z	cmp	rA1,rB1 wc wz
		mem[9'h0ca] = 32'b010111_0001_1111_000000000_000000000; // 00000328  00007c5c  mCMP15_ret	ret
		mem[9'h0cb] = 32'b011000_1000_1111_110111010_110111010; // 0000032c  ba753f62  mCMPRZ		test	rR,rR wz
		mem[9'h0cc] = 32'b011000_1000_1010_110111011_110111011; // 00000330  bb772b62  	if_z	test	rR1,rR1 wz
		mem[9'h0cd] = 32'b010111_0001_1111_000000000_000000000; // 00000334  00007c5c  mCMPRZ_ret	ret
		mem[9'h0ce] = 32'b011011_0010_1111_110110010_110110110; // 00000338  b665bf6c  XCHGAB		xor	rA,rB
		mem[9'h0cf] = 32'b011011_0010_1111_110110110_110110010; // 0000033c  b26dbf6c  		xor	rB,rA
		mem[9'h0d0] = 32'b011011_0010_1111_110110010_110110110; // 00000340  b665bf6c  		xor	rA,rB
		mem[9'h0d1] = 32'b011011_0010_1111_110110011_110110111; // 00000344  b767bf6c  		xor	rA1,rB1
		mem[9'h0d2] = 32'b011011_0010_1111_110110111_110110011; // 00000348  b36fbf6c  		xor	rB1,rA1
		mem[9'h0d3] = 32'b011011_0010_1111_110110011_110110111; // 0000034c  b767bf6c  		xor	rA1,rB1
		mem[9'h0d4] = 32'b011011_0010_1111_110110100_110111000; // 00000350  b869bf6c  		xor	rAExp,rBExp
		mem[9'h0d5] = 32'b011011_0010_1111_110111000_110110100; // 00000354  b471bf6c  		xor	rBExp,rAExp
		mem[9'h0d6] = 32'b011011_0010_1111_110110100_110111000; // 00000358  b869bf6c  		xor	rAExp,rBExp
		mem[9'h0d7] = 32'b011011_0010_1111_110110101_110111001; // 0000035c  b96bbf6c  		xor	rASgn,rBSgn
		mem[9'h0d8] = 32'b011011_0010_1111_110111001_110110101; // 00000360  b573bf6c  		xor	rBSgn,rASgn
		mem[9'h0d9] = 32'b011011_0010_1111_110110101_110111001; // 00000364  b96bbf6c  		xor	rASgn,rBSgn
		mem[9'h0da] = 32'b010111_0001_1111_000000000_000000000; // 00000368  00007c5c  XCHGAB_ret	ret
		mem[9'h0db] = 32'b101000_0010_1111_110111010_110110010; // 0000036c  b275bfa0  LOADATOR		mov	rR,rA
		mem[9'h0dc] = 32'b101000_0010_1111_110111011_110110011; // 00000370  b377bfa0  		mov	rR1,rA1
		mem[9'h0dd] = 32'b101000_0010_1111_110111100_110110100; // 00000374  b479bfa0  		mov	rRExp,rAExp
		mem[9'h0de] = 32'b101000_0010_1111_110111101_110111001; // 00000378  b97bbfa0  		mov	rRSgn,rBSgn
		mem[9'h0df] = 32'b010111_0001_1111_000000000_000000000; // 0000037c  00007c5c  LOADATOR_ret	ret
		mem[9'h0e0] = 32'b101000_0010_1111_110111010_110110110; // 00000380  b675bfa0  LOADBTOR		mov	rR,rB
		mem[9'h0e1] = 32'b101000_0010_1111_110111011_110110111; // 00000384  b777bfa0  		mov	rR1,rB1
		mem[9'h0e2] = 32'b101000_0010_1111_110111100_110111000; // 00000388  b879bfa0  		mov	rRExp,rBExp
		mem[9'h0e3] = 32'b101000_0010_1111_110111101_110111001; // 0000038c  b97bbfa0  		mov	rRSgn,rBSgn
		mem[9'h0e4] = 32'b010111_0001_1111_000000000_000000000; // 00000390  00007c5c  LOADBTOR_ret	ret
		mem[9'h0e5] = 32'b101000_0011_1111_110111010_000000000; // 00000394  0074ffa0  LOADZTOR		mov	rR,#0
		mem[9'h0e6] = 32'b101000_0011_1111_110111011_000000000; // 00000398  0076ffa0  		mov	rR1,#0
		mem[9'h0e7] = 32'b101000_0011_1111_110111100_000000000; // 0000039c  0078ffa0  		mov	rRExp,#0
		mem[9'h0e8] = 32'b101000_0011_1111_110111101_000000000; // 000003a0  007affa0  		mov	rRSgn,#0
		mem[9'h0e9] = 32'b010111_0001_1111_000000000_000000000; // 000003a4  00007c5c  LOADZTOR_ret	ret
		mem[9'h0ea] = 32'b000010_0010_1111_110110010_110110001; // 000003a8  b165bf08  LOADA		rdlong	rA,ptr1		' reads first long
		mem[9'h0eb] = 32'b100000_0011_1111_110110001_000000100; // 000003ac  0462ff80  		add	ptr1,#4
		mem[9'h0ec] = 32'b101000_0010_1111_110110101_110110010; // 000003b0  b26bbfa0  		mov	rASgn,rA
		mem[9'h0ed] = 32'b000010_0010_1111_110110011_110110001; // 000003b4  b167bf08  		rdlong	rA1,ptr1		' reads 2nd long
		mem[9'h0ee] = 32'b011000_0010_1111_110110101_111001011; // 000003b8  cb6bbf60  		and	rASgn,cnt_SMASK
		mem[9'h0ef] = 32'b011001_0010_1111_110110010_111001011; // 000003bc  cb65bf64  		andn	rA,cnt_SMASK
		mem[9'h0f0] = 32'b101000_0010_1111_110110100_110110011; // 000003c0  b369bfa0  		mov	rAExp,rA1
		mem[9'h0f1] = 32'b001011_0011_1111_110110100_000010100; // 000003c4  1468ff2c  		shl	rAExp,#20	' exponent is signed
		mem[9'h0f2] = 32'b001110_0011_1111_110110100_000010100; // 000003c8  1468ff38  		sar	rAExp,#20
		mem[9'h0f3] = 32'b011000_0010_1111_110110011_111001111; // 000003cc  cf67bf60  		and	rA1,cnt_2LMASK
		mem[9'h0f4] = 32'b010111_0001_1111_000000000_000000000; // 000003d0  00007c5c  LOADA_ret	ret
		mem[9'h0f5] = 32'b000010_0010_1111_110110110_110110001; // 000003d4  b16dbf08  LOADB		rdlong	rB,ptr1		' reads first long
		mem[9'h0f6] = 32'b100000_0011_1111_110110001_000000100; // 000003d8  0462ff80  		add	ptr1,#4
		mem[9'h0f7] = 32'b101000_0010_1111_110111001_110110110; // 000003dc  b673bfa0  		mov	rBSgn,rB
		mem[9'h0f8] = 32'b000010_0010_1111_110110111_110110001; // 000003e0  b16fbf08  		rdlong	rB1,ptr1		' reads 2nd long
		mem[9'h0f9] = 32'b011000_0010_1111_110111001_111001011; // 000003e4  cb73bf60  		and	rBSgn,cnt_SMASK
		mem[9'h0fa] = 32'b011001_0010_1111_110110110_111001011; // 000003e8  cb6dbf64  		andn	rB,cnt_SMASK
		mem[9'h0fb] = 32'b101000_0010_1111_110111000_110110111; // 000003ec  b771bfa0  		mov	rBExp,rB1
		mem[9'h0fc] = 32'b001011_0011_1111_110111000_000010100; // 000003f0  1470ff2c  		shl	rBExp,#20	' exponent is signed
		mem[9'h0fd] = 32'b001110_0011_1111_110111000_000010100; // 000003f4  1470ff38  		sar	rBExp,#20
		mem[9'h0fe] = 32'b011000_0010_1111_110110111_111001111; // 000003f8  cf6fbf60  		and	rB1,cnt_2LMASK
		mem[9'h0ff] = 32'b010111_0001_1111_000000000_000000000; // 000003fc  00007c5c  LOADB_ret	ret
		mem[9'h100] = 32'b101000_0010_1111_110111110_110111010; // 00000400  ba7dbfa0  SAVER		mov	rt1,rR
		mem[9'h101] = 32'b011010_0010_1111_110111110_110111101; // 00000404  bd7dbf68  		or	rt1,rRSgn
		mem[9'h102] = 32'b101000_0010_1111_110111111_110111100; // 00000408  bc7fbfa0  		mov	rt2,rRExp
		mem[9'h103] = 32'b011001_0010_1111_110111111_111001111; // 0000040c  cf7fbf64  		andn	rt2,cnt_2LMASK
		mem[9'h104] = 32'b101000_0010_1111_111000000_110111011; // 00000410  bb81bfa0  		mov	rt3,rR1
		mem[9'h105] = 32'b011000_0010_1111_111000000_111001111; // 00000414  cf81bf60  		and	rt3,cnt_2LMASK
		mem[9'h106] = 32'b000010_0000_1111_110111110_110110001; // 00000418  b17d3f08  		wrlong	rt1,ptr1
		mem[9'h107] = 32'b011010_0010_1111_110111111_111000000; // 0000041c  c07fbf68  		or	rt2,rt3
		mem[9'h108] = 32'b100000_0011_1111_110110001_000000100; // 00000420  0462ff80  		add	ptr1,#4
		mem[9'h109] = 32'b000010_0000_1111_110111111_110110001; // 00000424  b17f3f08  		wrlong	rt2,ptr1
		mem[9'h10a] = 32'b010111_0001_1111_000000000_000000000; // 00000428  00007c5c  SAVER_ret	ret
		mem[9'h10b] = 32'b101000_0010_1111_110111111_110111110; // 0000042c  be7fbfa0  MUL10		mov	rt2,rt1
		mem[9'h10c] = 32'b001011_0011_1111_110111111_000000011; // 00000430  037eff2c  		shl	rt2,#3
		mem[9'h10d] = 32'b100000_0010_1111_110111111_110111110; // 00000434  be7fbf80  		add	rt2,rt1
		mem[9'h10e] = 32'b100000_0010_1111_110111110_110111111; // 00000438  bf7dbf80  		add	rt1,rt2
		mem[9'h10f] = 32'b010111_0001_1111_000000000_000000000; // 0000043c  00007c5c  MUL10_ret	ret
		mem[9'h110] = 32'b101000_0011_1111_110111110_000000000; // 00000440  007cffa0  RTOINT		mov	rt1,#0		' clears result
		mem[9'h111] = 32'b101000_0110_1111_110111100_110111100; // 00000444  bc79bfa1  		mov	rRExp,rRExp wc	' tests for < 0
		mem[9'h112] = 32'b010111_0001_1100_000000000_100011111; // 00000448  1f01705c  	if_c	jmp	#RTOINT_ret
		mem[9'h113] = 32'b100001_0101_1111_110111100_000001001; // 0000044c  09787f85  		cmp	rRExp,#9 wc
		mem[9'h114] = 32'b100001_0011_0011_110111110_000000001; // 00000450  017ccf84  	if_nc	sub	rt1,#1		' overflow
		mem[9'h115] = 32'b010111_0001_0011_000000000_100011111; // 00000454  1f014c5c  	if_nc	jmp	#RTOINT_ret
		mem[9'h116] = 32'b010111_0011_1111_010111011_010110111; // 00000458  b776fd5c  		call	#mSHLR15		' will use up to 8 digits
		mem[9'h117] = 32'b101000_0010_1111_111000000_110111100; // 0000045c  bc81bfa0  		mov	rt3,rRExp
		mem[9'h118] = 32'b100000_0011_1111_111000000_000000001; // 00000460  0180ff80  		add	rt3,#1
		mem[9'h119] = 32'b010111_0011_1111_100001111_100001011; // 00000464  0b1ffe5c  RTOINT_5		call	#MUL10
		mem[9'h11a] = 32'b001001_0011_1111_110111010_000000100; // 00000468  0474ff24  		rol	rR,#4
		mem[9'h11b] = 32'b101000_0010_1111_111000001_110111010; // 0000046c  ba83bfa0  		mov	rt4,rR
		mem[9'h11c] = 32'b011000_0011_1111_111000001_000001111; // 00000470  0f82ff60  		and	rt4,#$f
		mem[9'h11d] = 32'b100000_0010_1111_110111110_111000001; // 00000474  c17dbf80  		add	rt1,rt4
		mem[9'h11e] = 32'b111001_0011_1111_111000000_100011001; // 00000478  1981ffe4  		djnz	rt3,#RTOINT_5
		mem[9'h11f] = 32'b010111_0001_1111_000000000_000000000; // 0000047c  00007c5c  RTOINT_ret	ret
		mem[9'h120] = 32'b101000_0110_1111_110111100_110111100; // 00000480  bc79bfa1  TOASCIIQD	mov	rRExp,rRExp wc 	'checks for negative exponent,
		mem[9'h121] = 32'b101000_0011_1100_110111110_000110000; // 00000484  307cf3a0  	if_c	mov	rt1,#48
		mem[9'h122] = 32'b010111_0011_1100_101010111_101010101; // 00000488  55aff25c  	if_c	call	#EMITASCII
		mem[9'h123] = 32'b010111_0001_1100_000000000_100110010; // 0000048c  3201705c  	if_c	jmp	#TOASCIIQD_40
		mem[9'h124] = 32'b100001_0101_1111_110111100_000000101; // 00000490  05787f85  		cmp	rRExp,#5 wc
		mem[9'h125] = 32'b101000_0011_0011_110111110_001000101; // 00000494  457ccfa0  	if_nc	mov	rt1,#69		' E signals error
		mem[9'h126] = 32'b010111_0011_0011_101010111_101010101; // 00000498  55afce5c  	if_nc	call	#EMITASCII
		mem[9'h127] = 32'b010111_0001_0011_000000000_100110010; // 0000049c  32014c5c  	if_nc	jmp	#TOASCIIQD_40
		mem[9'h128] = 32'b101000_0010_1111_110111111_110111100; // 000004a0  bc7fbfa0  		mov	rt2,rRExp
		mem[9'h129] = 32'b100000_0011_1111_110111111_000000001; // 000004a4  017eff80  		add	rt2,#1
		mem[9'h12a] = 32'b101000_0010_1111_111000000_110111010; // 000004a8  ba81bfa0  		mov	rt3,rR		' working significant
		mem[9'h12b] = 32'b101000_0010_1111_110111110_111000000; // 000004ac  c07dbfa0  TOASCIIQD_10	mov	rt1,rt3
		mem[9'h12c] = 32'b001010_0011_1111_110111110_000011000; // 000004b0  187cff28  		shr	rt1,#24
		mem[9'h12d] = 32'b011000_0011_1111_110111110_000001111; // 000004b4  0f7cff60  		and	rt1,#15
		mem[9'h12e] = 32'b100000_0011_1111_110111110_000110000; // 000004b8  307cff80  		add	rt1,#48		' converts digit to ASCII
		mem[9'h12f] = 32'b010111_0011_1111_101010111_101010101; // 000004bc  55affe5c  		call	#EMITASCII
		mem[9'h130] = 32'b001011_0011_1111_111000000_000000100; // 000004c0  0480ff2c  		shl	rt3,#4
		mem[9'h131] = 32'b111001_0011_1111_110111111_100101011; // 000004c4  2b7fffe4  		djnz	rt2,#TOASCIIQD_10
		mem[9'h132] = 32'b101000_0011_1111_110111110_000000000; // 000004c8  007cffa0  TOASCIIQD_40	mov	rt1,#0
		mem[9'h133] = 32'b010111_0011_1111_101010111_101010101; // 000004cc  55affe5c  		call	#EMITASCII
		mem[9'h134] = 32'b010111_0001_1111_000000000_000000000; // 000004d0  00007c5c  TOASCIIQD_ret	ret
		mem[9'h135] = 32'b101000_0110_1111_110111100_110111100; // 000004d4  bc79bfa1  TOASCIIQDR	mov	rRExp,rRExp wc 	'checks for negative exponent,
		mem[9'h136] = 32'b101000_0011_1100_110111110_000110000; // 000004d8  307cf3a0  	if_c	mov	rt1,#48
		mem[9'h137] = 32'b010111_0011_1100_101010111_101010101; // 000004dc  55aff25c  	if_c	call	#EMITASCII
		mem[9'h138] = 32'b010111_0001_1100_000000000_101010010; // 000004e0  5201705c  	if_c	jmp	#TOASCIIQDR_40
		mem[9'h139] = 32'b100001_0101_1111_110111100_000000101; // 000004e4  05787f85  		cmp	rRExp,#5 wc
		mem[9'h13a] = 32'b101000_0011_0011_110111110_001000101; // 000004e8  457ccfa0  	if_nc	mov	rt1,#69		' E signals error
		mem[9'h13b] = 32'b010111_0011_0011_101010111_101010101; // 000004ec  55afce5c  	if_nc	call	#EMITASCII
		mem[9'h13c] = 32'b010111_0001_0011_000000000_101010010; // 000004f0  52014c5c  	if_nc	jmp	#TOASCIIQDR_40
		mem[9'h13d] = 32'b101000_0010_1111_110111110_110111010; // 000004f4  ba7dbfa0  		mov	rt1,rR
		mem[9'h13e] = 32'b101000_0011_1111_110111111_000000101; // 000004f8  057effa0  		mov	rt2,#5		' rounding argument
		mem[9'h13f] = 32'b101000_0011_1111_111000000_000000101; // 000004fc  0580ffa0  		mov	rt3,#5
		mem[9'h140] = 32'b100001_0010_1111_111000000_110111100; // 00000500  bc81bf84  		sub	rt3,rRExp
		mem[9'h141] = 32'b001011_0011_1111_111000000_000000010; // 00000504  0280ff2c  		shl	rt3,#2
		mem[9'h142] = 32'b001011_0010_1111_110111111_111000000; // 00000508  c07fbf2c  		shl	rt2,rt3		' adjust rounding digit
		mem[9'h143] = 32'b010111_0011_1111_010001111_001111010; // 0000050c  7a1efd5c  		call	#mADD8
		mem[9'h144] = 32'b101000_0010_1111_110111111_110111100; // 00000510  bc7fbfa0  		mov	rt2,rRExp
		mem[9'h145] = 32'b011000_1000_1111_111000010_111001100; // 00000514  cc853f62  		test	rt5,cnt_MSD wz
		mem[9'h146] = 32'b100000_0011_0101_110111111_000000001; // 00000518  017ed780  	if_nz	add	rt2,#1		' increments exponent if overflow
		mem[9'h147] = 32'b001010_0011_0101_111000010_000000100; // 0000051c  0484d728  	if_nz	shr	rt5,#4		' shifts working significant one to the right
		mem[9'h148] = 32'b100001_0101_1111_110111111_000000101; // 00000520  057e7f85  		cmp	rt2,#5	wc
		mem[9'h149] = 32'b010111_0001_0011_000000000_100111010; // 00000524  3a014c5c  	if_nc	jmp	#TOASCIIQDR_5
		mem[9'h14a] = 32'b100000_0011_1111_110111111_000000001; // 00000528  017eff80  		add	rt2,#1
		mem[9'h14b] = 32'b101000_0010_1111_110111110_111000010; // 0000052c  c27dbfa0  TOASCIIQDR_10	mov	rt1,rt5
		mem[9'h14c] = 32'b001010_0011_1111_110111110_000011000; // 00000530  187cff28  		shr	rt1,#24
		mem[9'h14d] = 32'b011000_0011_1111_110111110_000001111; // 00000534  0f7cff60  		and	rt1,#15
		mem[9'h14e] = 32'b100000_0011_1111_110111110_000110000; // 00000538  307cff80  		add	rt1,#48		' converts digit to ASCII
		mem[9'h14f] = 32'b010111_0011_1111_101010111_101010101; // 0000053c  55affe5c  		call	#EMITASCII
		mem[9'h150] = 32'b001011_0011_1111_111000010_000000100; // 00000540  0484ff2c  		shl	rt5,#4
		mem[9'h151] = 32'b111001_0011_1111_110111111_101001011; // 00000544  4b7fffe4  		djnz	rt2,#TOASCIIQDR_10
		mem[9'h152] = 32'b101000_0011_1111_110111110_000000000; // 00000548  007cffa0  TOASCIIQDR_40	mov	rt1,#0
		mem[9'h153] = 32'b010111_0011_1111_101010111_101010101; // 0000054c  55affe5c  		call	#EMITASCII
		mem[9'h154] = 32'b010111_0001_1111_000000000_000000000; // 00000550  00007c5c  TOASCIIQDR_ret	ret
		mem[9'h155] = 32'b000000_0000_1111_110111110_110110001; // 00000554  b17d3f00  EMITASCII	wrbyte	rt1,ptr1
		mem[9'h156] = 32'b100000_0011_1111_110110001_000000001; // 00000558  0162ff80  		add	ptr1,#1
		mem[9'h157] = 32'b010111_0001_1111_000000000_000000000; // 0000055c  00007c5c  EMITASCII_ret	ret
		mem[9'h158] = 32'b010111_0001_1111_000000000_110000000; // 00000560  00007c5c  ASCIITOBCD_ret  ret
		mem[9'h159] = 32'b010111_0011_1111_110101000_110100110; // 00000564  a651ff5c  BCDSQR15        call    #mCMPAZ
		mem[9'h15a] = 32'b010111_0011_1010_011101001_011100101; // 00000568  e5d2e95c          if_z    call    #LOADZTOR
		mem[9'h15b] = 32'b010111_0001_1010_000000000_110010011; // 0000056c  9301685c          if_z    jmp     #BCDSQR15_ret       ' argument is zero
		mem[9'h15c] = 32'b100001_1001_1111_110110101_000000000; // 00000570  006a7f86                  cmp     rASgn,#0 wz
		mem[9'h15d] = 32'b101000_0011_0101_111001010_000000011; // 00000574  0394d7a0          if_nz   mov     rerr,#ERR_SQRN      ' argument is negative
		mem[9'h15e] = 32'b010111_0001_0101_000000000_110010011; // 00000578  9301545c          if_nz   jmp     #BCDSQR15_ret
		mem[9'h15f] = 32'b101000_0010_1111_110110111_110110011; // 0000057c  b36fbfa0                  mov     rB1,rA1             ' calculates 1/2*Significant
		mem[9'h160] = 32'b101000_0010_1111_110110110_110110010; // 00000580  b26dbfa0                  mov     rB,rA
		mem[9'h161] = 32'b010111_0011_1111_110011100_110010100; // 00000584  9439ff5c                  call    #mADDBB
		mem[9'h162] = 32'b010111_0011_1111_110011100_110010100; // 00000588  9439ff5c                  call    #mADDBB
		mem[9'h163] = 32'b010111_0011_1111_110100101_110011101; // 0000058c  9d4bff5c                  call    #mADDAB             ' A=0.5*Old_significant
		mem[9'h164] = 32'b010111_0011_1111_011101001_011100101; // 00000590  e5d2fd5c                  call    #LOADZTOR           ' clears R
		mem[9'h165] = 32'b101000_0010_1111_110111100_110110100; // 00000594  b479bfa0                  mov     rRExp,rAExp
		mem[9'h166] = 32'b001110_0011_1111_110111100_000000001; // 00000598  0178ff38                  sar     rRExp,#1            ' exponent of result
		mem[9'h167] = 32'b101000_0010_1111_110111110_110110100; // 0000059c  b47dbfa0                  mov     rt1,rAExp
		mem[9'h168] = 32'b110100_0010_1111_110111110_110111110; // 000005a0  be7dbfd0                  adds    rt1,rt1
		mem[9'h169] = 32'b100000_0010_1111_110111110_110111110; // 000005a4  be7dbf80                  add     rt1,rt1	        ' * 4
		mem[9'h16a] = 32'b100000_0010_1111_110111110_110110100; // 000005a8  b47dbf80                  add     rt1,rAExp           ' * 5
		mem[9'h16b] = 32'b011000_1001_1111_110111110_000000001; // 000005ac  017c7f62                  test    rt1,#1 wz
		mem[9'h16c] = 32'b010111_0011_1010_010101011_010100111; // 000005b0  a756e95c          if_z    call    #mSHRA15            ' shift right if exponent was even
		mem[9'h16d] = 32'b101000_0010_1111_111000011_111010000; // 000005b4  d087bfa0                  mov     rt6,cnt_FIVE
		mem[9'h16e] = 32'b101000_0011_1111_111000100_000000000; // 000005b8  0088ffa0                  mov     rt7,#0              ' rt6:rt7 is used to calculate the digits
		mem[9'h16f] = 32'b101000_0010_1111_110110110_111001110; // 000005bc  ce6dbfa0                  mov     rB,cnt_ONE
		mem[9'h170] = 32'b101000_0011_1111_110110111_000000000; // 000005c0  006effa0                  mov     rB1,#0              ' we initialize constant
		mem[9'h171] = 32'b101000_0011_1111_111000101_000001101; // 000005c4  0d8affa0                  mov     rt8,#13             ' 12 digits
		mem[9'h172] = 32'b010111_0001_1111_000000000_110010001; // 000005c8  91017c5c  BCDSQR15_10     jmp     #BCDSQR15_25
		mem[9'h173] = 32'b100001_1100_1111_110110010_110111010; // 000005cc  ba653f87  BCDSQR15_17     cmp     rA,rR wz wc
		mem[9'h174] = 32'b100001_1100_1010_110110011_110111011; // 000005d0  bb672b87          if_z    cmp     rA1,rR1 wz wc
		mem[9'h175] = 32'b010111_0001_1100_000000000_110001111; // 000005d4  8f01705c          if_c    jmp     #BCDSQR15_20
		mem[9'h176] = 32'b101000_0010_1111_110111110_110110011; // 000005d8  b37dbfa0                  mov     rt1,rA1
		mem[9'h177] = 32'b101000_0010_1111_110111111_110111011; // 000005dc  bb7fbfa0                  mov     rt2,rR1
		mem[9'h178] = 32'b010111_0011_1111_010100000_010010000; // 000005e0  9040fd5c                  call    #mSUB8
		mem[9'h179] = 32'b101000_0010_1111_110110011_111000010; // 000005e4  c267bfa0                  mov     rA1,rt5
		mem[9'h17a] = 32'b101000_0010_1111_110111110_110110010; // 000005e8  b27dbfa0                  mov     rt1,rA
		mem[9'h17b] = 32'b101000_0010_1111_110111111_110111010; // 000005ec  ba7fbfa0                  mov     rt2,rR
		mem[9'h17c] = 32'b010111_0011_1111_010100000_010010001; // 000005f0  9140fd5c                  call    #mSUB8C
		mem[9'h17d] = 32'b101000_0010_1111_110110010_111000010; // 000005f4  c265bfa0                  mov     rA,rt5
		mem[9'h17e] = 32'b101000_0010_1111_110111110_110110011; // 000005f8  b37dbfa0                  mov     rt1,rA1
		mem[9'h17f] = 32'b101000_0010_1111_110111111_111000100; // 000005fc  c47fbfa0                  mov     rt2,rt7
		mem[9'h180] = 32'b010111_0011_1111_010100000_010010000; // 00000600  9040fd5c                  call    #mSUB8
		mem[9'h181] = 32'b101000_0010_1111_110110011_111000010; // 00000604  c267bfa0                  mov     rA1,rt5
		mem[9'h182] = 32'b101000_0010_1111_110111110_110110010; // 00000608  b27dbfa0                  mov     rt1,rA
		mem[9'h183] = 32'b101000_0010_1111_110111111_111000011; // 0000060c  c37fbfa0                  mov     rt2,rt6
		mem[9'h184] = 32'b010111_0011_1111_010100000_010010001; // 00000610  9140fd5c                  call    #mSUB8C
		mem[9'h185] = 32'b101000_0010_1111_110110010_111000010; // 00000614  c265bfa0                  mov     rA,rt5
		mem[9'h186] = 32'b101000_0010_1111_110111110_110111011; // 00000618  bb7dbfa0                  mov     rt1,rR1
		mem[9'h187] = 32'b101000_0010_1111_110111111_110110111; // 0000061c  b77fbfa0                  mov     rt2,rB1
		mem[9'h188] = 32'b010111_0011_1111_010001111_001111010; // 00000620  7a1efd5c                  call    #mADD8
		mem[9'h189] = 32'b101000_0010_1111_110111011_111000010; // 00000624  c277bfa0                  mov     rR1,rt5
		mem[9'h18a] = 32'b101000_0010_1111_110111110_110111010; // 00000628  ba7dbfa0                  mov     rt1,rR
		mem[9'h18b] = 32'b101000_0010_1111_110111111_110110110; // 0000062c  b67fbfa0                  mov     rt2,rB
		mem[9'h18c] = 32'b010111_0011_1111_010001111_001111100; // 00000630  7c1efd5c                  call    #mADD8C
		mem[9'h18d] = 32'b101000_0010_1111_110111010_111000010; // 00000634  c275bfa0                  mov     rR,rt5
		mem[9'h18e] = 32'b010111_0001_1111_000000000_101110011; // 00000638  73017c5c                  jmp     #BCDSQR15_17
		mem[9'h18f] = 32'b010111_0011_1111_010100110_010100001; // 0000063c  a14cfd5c  BCDSQR15_20     call    #mSHLA15              ' shifts left
		mem[9'h190] = 32'b010111_0011_1111_010110110_010110001; // 00000640  b16cfd5c                  call    #mSHRB15
		mem[9'h191] = 32'b010111_0011_1111_011000111_011000010; // 00000644  c28efd5c  BCDSQR15_25     call    #mSHR6715
		mem[9'h192] = 32'b111001_0011_1111_111000101_101110011; // 00000648  738bffe4                  djnz    rt8,#BCDSQR15_17
		mem[9'h193] = 32'b010111_0001_1111_000000000_000000000; // 0000064c  00007c5c  BCDSQR15_ret    ret
		mem[9'h194] = 32'b101000_0010_1111_110111110_110110111; // 00000650  b77dbfa0  mADDBB          mov     rt1,rB1
		mem[9'h195] = 32'b101000_0010_1111_110111111_110110111; // 00000654  b77fbfa0                  mov     rt2,rB1
		mem[9'h196] = 32'b010111_0011_1111_010001111_001111010; // 00000658  7a1efd5c                  call    #mADD8
		mem[9'h197] = 32'b101000_0010_1111_110110111_111000010; // 0000065c  c26fbfa0                  mov     rB1,rt5
		mem[9'h198] = 32'b101000_0010_1111_110111110_110110110; // 00000660  b67dbfa0                  mov     rt1,rB
		mem[9'h199] = 32'b101000_0010_1111_110111111_110110110; // 00000664  b67fbfa0                  mov     rt2,rB
		mem[9'h19a] = 32'b010111_0011_1111_010001111_001111100; // 00000668  7c1efd5c                  call    #mADD8C
		mem[9'h19b] = 32'b101000_0010_1111_110110110_111000010; // 0000066c  c26dbfa0                  mov     rB,rt5
		mem[9'h19c] = 32'b010111_0001_1111_000000000_000000000; // 00000670  00007c5c  mADDBB_ret      ret
		mem[9'h19d] = 32'b101000_0010_1111_110111110_110110011; // 00000674  b37dbfa0  mADDAB          mov     rt1,rA1
		mem[9'h19e] = 32'b101000_0010_1111_110111111_110110111; // 00000678  b77fbfa0                  mov     rt2,rB1
		mem[9'h19f] = 32'b010111_0011_1111_010001111_001111010; // 0000067c  7a1efd5c                  call    #mADD8
		mem[9'h1a0] = 32'b101000_0010_1111_110110011_111000010; // 00000680  c267bfa0                  mov     rA1,rt5
		mem[9'h1a1] = 32'b101000_0010_1111_110111110_110110010; // 00000684  b27dbfa0                  mov     rt1,rA
		mem[9'h1a2] = 32'b101000_0010_1111_110111111_110110110; // 00000688  b67fbfa0                  mov     rt2,rB
		mem[9'h1a3] = 32'b010111_0011_1111_010001111_001111100; // 0000068c  7c1efd5c                  call    #mADD8C
		mem[9'h1a4] = 32'b101000_0010_1111_110110010_111000010; // 00000690  c265bfa0                  mov     rA,rt5
		mem[9'h1a5] = 32'b010111_0001_1111_000000000_000000000; // 00000694  00007c5c  mADDAB_ret      ret
		mem[9'h1a6] = 32'b011000_1000_1111_110110010_110110010; // 00000698  b2653f62  mCMPAZ          test    rA,rA wz
		mem[9'h1a7] = 32'b011000_1000_1010_110110011_110110011; // 0000069c  b3672b62          if_z    test    rA1,rA1 wz
		mem[9'h1a8] = 32'b010111_0001_1111_000000000_000000000; // 000006a0  00007c5c  mCMPAZ_ret      ret
		mem[9'h1a9] = 32'b011000_1000_1111_110110110_110110110; // 000006a4  b66d3f62  mCMPBZ          test    rB,rB wz
		mem[9'h1aa] = 32'b011000_1000_1010_110110111_110110111; // 000006a8  b76f2b62          if_z    test    rB1,rB1 wz
		mem[9'h1ab] = 32'b010111_0001_1111_000000000_000000000; // 000006ac  00007c5c  mCMPBZ_ret      ret
		mem[9'h1ac] = 32'b100001_1100_1111_110110010_110110110; // 000006b0  b6653f87  mCMPAB          cmp     rA,rB wc wz
		mem[9'h1ad] = 32'b100001_1100_1010_110110011_110110111; // 000006b4  b7672b87          if_z    cmp     rA1,rB1 wc wz
		mem[9'h1ae] = 32'b010111_0001_1111_000000000_000000000; // 000006b8  00007c5c  mCMPAB_ret      ret
		mem[9'h1af] = 32'b100001_0101_1111_111000101_000000101; // 000006bc  058a7f85  mSHRRP          cmp     rt8,#5 wc
		mem[9'h1b0] = 32'b010111_0001_1111_000000000_110110001; // 000006c0  b1017c5c                  jmp     #mSHRRP_20            ' we will see
		mem[9'h1b1] = 32'b000000_0000_0000_000000000_000000000; // 000006c4  00000000  ptr1		long 0
		mem[9'h1b2] = 32'b000000_0100_0000_000000000_000000000; // 000006c8  00003001  rA		long $01000000
		mem[9'h1b3] = 32'b000000_0000_0000_000000000_000000000; // 000006cc  00000000  rA1		long $00000000
		mem[9'h1b4] = 32'b000000_0000_0000_000000000_000110011; // 000006d0  33000000  rAExp		long 51
		mem[9'h1b5] = 32'b000000_0000_0000_000000000_000000000; // 000006d4  00000000  rASgn		long 0
		mem[9'h1b6] = 32'b000000_1110_0001_000000000_000000000; // 000006d8  00008403  rB		long $03840000
		mem[9'h1b7] = 32'b000000_0000_0000_000000000_000000000; // 000006dc  00000000  rB1		long $00000000
		mem[9'h1b8] = 32'b000000_0000_0000_000000000_000000101; // 000006e0  05000000  rBExp		long $5
		mem[9'h1b9] = 32'b000000_0000_0000_000000000_000000000; // 000006e4  00000000  rBSgn		long $0000_0000
		mem[9'h1ba] = 32'b000000_0000_0000_000000000_000000000; // 000006e8  00000000  rR		long 0
		mem[9'h1bb] = 32'b000000_0000_0000_000000000_000000000; // 000006ec  00000000  rR1		long 0
		mem[9'h1bc] = 32'b000000_0000_0000_000000000_000000000; // 000006f0  00000000  rRExp		long 0
		mem[9'h1bd] = 32'b000000_0000_0000_000000000_000000000; // 000006f4  00000000  rRSgn		long 0
		mem[9'h1be] = 32'b000000_0000_0000_000000000_000000000; // 000006f8  00000000  rt1		long 0
		mem[9'h1bf] = 32'b000000_0000_0000_000000000_000000000; // 000006fc  00000000  rt2		long 0
		mem[9'h1c0] = 32'b000000_0000_0000_000000000_000000000; // 00000700  00000000  rt3		long 0
		mem[9'h1c1] = 32'b000000_0000_0000_000000000_000000000; // 00000704  00000000  rt4		long 0
		mem[9'h1c2] = 32'b000000_0000_0000_000000000_000000000; // 00000708  00000000  rt5		long 0
		mem[9'h1c3] = 32'b000000_0000_0000_000000000_000000000; // 0000070c  00000000  rt6		long 0
		mem[9'h1c4] = 32'b000000_0000_0000_000000000_000000000; // 00000710  00000000  rt7		long 0
		mem[9'h1c5] = 32'b000000_0000_0000_000000000_000000000; // 00000714  00000000  rt8               long 0
		mem[9'h1c6] = 32'b000000_0000_0000_000000000_000000000; // 00000718  00000000  rcarry		long 0
		mem[9'h1c7] = 32'b000000_0000_0000_000000000_000000000; // 0000071c  00000000  rcnt1		long 0
		mem[9'h1c8] = 32'b000000_0000_0000_000000000_000000000; // 00000720  00000000  rmsk1		long 0
		mem[9'h1c9] = 32'b000000_0000_0000_000000000_000000000; // 00000724  00000000  rsh1		long 0
		mem[9'h1ca] = 32'b000000_0000_0000_000000000_000000000; // 00000728  00000000  rerr              long 0
		mem[9'h1cb] = 32'b100000_0000_0000_000000000_000000000; // 0000072c  00000080  cnt_SMASK	long	$8000_0000	' sign mask
		mem[9'h1cc] = 32'b111100_0000_0000_000000000_000000000; // 00000730  000000f0  cnt_MSD   	long	$f000_0000
		mem[9'h1cd] = 32'b000011_1100_0000_000000000_000000000; // 00000734  0000000f  cnt_D12   	long	$0f00_0000
		mem[9'h1ce] = 32'b000000_0100_0000_000000000_000000000; // 00000738  00000001  cnt_ONE		long	$0100_0000
		mem[9'h1cf] = 32'b111111_1111_1111_111111000_000000000; // 0000073c  00f0ffff  cnt_2LMASK	long	$ffff_f000
		mem[9'h1d0] = 32'b000001_0100_0000_000000000_000000000; // 00000740  00000005  cnt_FIVE          long     $0500_0000
		mem[9'h1e0] = 32'h0000_000e; // test value
*/                    //OOOOOOZCRiCCCCDDDDDDDDDSSSSSSSSS
/*
		mem[   0] = 32'b10100000111111111110100000000011; //-- mov dira, #3
		mem[   1] = 32'b10100000101111111100000111110001; //-- mov temp, CNT ($1E0)
		mem[   2] = 32'b10000000111111111100000000100000; //-- add temp, #32
		mem[   3] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[   4] = 32'b10100000111111111110110000000010; //-- mov porta, #2
		mem[   5] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[   6] = 32'b10100000111111111110110000000001; //-- mov porta, #1
		mem[   7] = 32'b01011100011111000000000000000011; //-- jmp #3
		mem[   8] = 32'b001110_1111_0010_001000100_001000001; // mov rt, rA20
		mem[   9] = 32'b001110_1111_0010_001000100_001000001; // mov rt, rA20
		mem[ 128] = 32'b111100_0011_1100_001111000_011110000; // mov rt, rA20
*/
	end
endmodule
`endif