/* 
 * AProp
 *
 * Top Module. This is the top module for simulation and synthesis.
 * The targets are selected using macros
 *
 * target    | macro defined by the sythesis tool (add if necessary)
 *-----------+---------------
 * Altera CV | ALTERA_CV=1
 * icarus    | IVERILOG=1
 * Lattice   | LATTICE_MACHXO2=1
 *
 +
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
`include "acog_defs.v"  
`define WITH_PORTB 1
`define TWO_COGS 1
`define HW_DEBUG 1
module AProp(
	input wire clk_in,
	input wire reset_in,
	
	inout wire [31:0] port_a
`ifdef WITH_PORTB
	,inout wire [31:0] port_b
`endif
	,
	output wire debug_clk_o,
	output wire debug_data_o,
	output wire debug_cs_o
	);

wire [31:0] CNT;
	
wire [31:0] port_a_in, mux_port_a_out;
wire [31:0] port_a_dir;
wire [31:0] port_a_o_0, port_a_dir_o_0;
wire [31:0] port_a_o_1, port_a_dir_o_1;

`ifdef WITH_PORTB
wire [31:0] port_b_in, mux_port_b_out;
wire [31:0] port_b_dir;
wire [31:0] port_b_o_0, port_b_dir_o_0;
wire [31:0] port_b_o_1, port_b_dir_o_1;
`endif

`ifdef TWO_COGS
`else
assign port_a_o_1 = 32'h0;
assign port_a_dir_o_1 = 32'h0;
`endif

// PORT A *******
assign port_a_in = port_a;
assign mux_port_a_out = port_a_o_0 | port_a_o_1;
assign port_a_dir = port_a_dir_o_0 | port_a_dir_o_1;

assign port_a[ 0] = port_a_dir[ 0] ? mux_port_a_out[ 0]:1'bz; 
assign port_a[ 1] = port_a_dir[ 1] ? mux_port_a_out[ 1]:1'bz; 
assign port_a[ 2] = port_a_dir[ 2] ? mux_port_a_out[ 2]:1'bz; 
assign port_a[ 3] = port_a_dir[ 3] ? mux_port_a_out[ 3]:1'bz; 
assign port_a[ 4] = port_a_dir[ 4] ? mux_port_a_out[ 4]:1'bz; 
assign port_a[ 5] = port_a_dir[ 5] ? mux_port_a_out[ 5]:1'bz; 
assign port_a[ 6] = port_a_dir[ 6] ? mux_port_a_out[ 6]:1'bz; 
assign port_a[ 7] = port_a_dir[ 7] ? mux_port_a_out[ 7]:1'bz; 
assign port_a[ 8] = port_a_dir[ 8] ? mux_port_a_out[ 8]:1'bz; 
assign port_a[ 9] = port_a_dir[ 9] ? mux_port_a_out[ 9]:1'bz;
assign port_a[10] = port_a_dir[10] ? mux_port_a_out[10]:1'bz; 
assign port_a[11] = port_a_dir[11] ? mux_port_a_out[11]:1'bz; 
assign port_a[12] = port_a_dir[12] ? mux_port_a_out[12]:1'bz; 
assign port_a[13] = port_a_dir[13] ? mux_port_a_out[13]:1'bz; 
assign port_a[14] = port_a_dir[14] ? mux_port_a_out[14]:1'bz; 
assign port_a[15] = port_a_dir[15] ? mux_port_a_out[15]:1'bz; 
assign port_a[16] = port_a_dir[16] ? mux_port_a_out[16]:1'bz; 
assign port_a[17] = port_a_dir[17] ? mux_port_a_out[17]:1'bz; 
assign port_a[18] = port_a_dir[18] ? mux_port_a_out[18]:1'bz; 
assign port_a[19] = port_a_dir[19] ? mux_port_a_out[19]:1'bz;
assign port_a[20] = port_a_dir[20] ? mux_port_a_out[20]:1'bz; 
assign port_a[21] = port_a_dir[21] ? mux_port_a_out[21]:1'bz; 
assign port_a[22] = port_a_dir[22] ? mux_port_a_out[22]:1'bz; 
assign port_a[23] = port_a_dir[23] ? mux_port_a_out[23]:1'bz; 
assign port_a[24] = port_a_dir[24] ? mux_port_a_out[24]:1'bz; 
assign port_a[25] = port_a_dir[25] ? mux_port_a_out[25]:1'bz; 
assign port_a[26] = port_a_dir[26] ? mux_port_a_out[26]:1'bz; 
assign port_a[27] = port_a_dir[27] ? mux_port_a_out[27]:1'bz; 
assign port_a[28] = port_a_dir[28] ? mux_port_a_out[28]:1'bz; 
assign port_a[29] = port_a_dir[29] ? mux_port_a_out[29]:1'bz;
assign port_a[30] = port_a_dir[30] ? mux_port_a_out[30]:1'bz; 
assign port_a[31] = port_a_dir[31] ? mux_port_a_out[31]:1'bz; 

`ifdef WITH_PORTB  //// PORT B ******

assign port_b_in = port_b;
assign mux_port_b_out = port_b_o_0 | port_b_o_1;
assign port_b_dir = port_b_dir_o_0 | port_b_dir_o_1;

assign port_b[ 0] = port_b_dir[ 0] ? mux_port_b_out[ 0]:1'bz; 
assign port_b[ 1] = port_b_dir[ 1] ? mux_port_b_out[ 1]:1'bz; 
assign port_b[ 2] = port_b_dir[ 2] ? mux_port_b_out[ 2]:1'bz; 
assign port_b[ 3] = port_b_dir[ 3] ? mux_port_b_out[ 3]:1'bz; 
assign port_b[ 4] = port_b_dir[ 4] ? mux_port_b_out[ 4]:1'bz; 
assign port_b[ 5] = port_b_dir[ 5] ? mux_port_b_out[ 5]:1'bz; 
assign port_b[ 6] = port_b_dir[ 6] ? mux_port_b_out[ 6]:1'bz; 
assign port_b[ 7] = port_b_dir[ 7] ? mux_port_b_out[ 7]:1'bz; 
assign port_b[ 8] = port_b_dir[ 8] ? mux_port_b_out[ 8]:1'bz; 
assign port_b[ 9] = port_b_dir[ 9] ? mux_port_b_out[ 9]:1'bz;
assign port_b[10] = port_b_dir[10] ? mux_port_b_out[10]:1'bz; 
assign port_b[11] = port_b_dir[11] ? mux_port_b_out[11]:1'bz; 
assign port_b[12] = port_b_dir[12] ? mux_port_b_out[12]:1'bz; 
assign port_b[13] = port_b_dir[13] ? mux_port_b_out[13]:1'bz; 
assign port_b[14] = port_b_dir[14] ? mux_port_b_out[14]:1'bz; 
assign port_b[15] = port_b_dir[15] ? mux_port_b_out[15]:1'bz; 
assign port_b[16] = port_b_dir[16] ? mux_port_b_out[16]:1'bz; 
assign port_b[17] = port_b_dir[17] ? mux_port_b_out[17]:1'bz; 
assign port_b[18] = port_b_dir[18] ? mux_port_b_out[18]:1'bz; 
assign port_b[19] = port_b_dir[19] ? mux_port_b_out[19]:1'bz;
assign port_b[20] = port_b_dir[20] ? mux_port_b_out[20]:1'bz; 
assign port_b[21] = port_b_dir[21] ? mux_port_b_out[21]:1'bz; 
assign port_b[22] = port_b_dir[22] ? mux_port_b_out[22]:1'bz; 
assign port_b[23] = port_b_dir[23] ? mux_port_b_out[23]:1'bz; 
assign port_b[24] = port_b_dir[24] ? mux_port_b_out[24]:1'bz; 
assign port_b[25] = port_b_dir[25] ? mux_port_b_out[25]:1'bz; 
assign port_b[26] = port_b_dir[26] ? mux_port_b_out[26]:1'bz; 
assign port_b[27] = port_b_dir[27] ? mux_port_b_out[27]:1'bz; 
assign port_b[28] = port_b_dir[28] ? mux_port_b_out[28]:1'bz; 
assign port_b[29] = port_b_dir[29] ? mux_port_b_out[29]:1'bz;
assign port_b[30] = port_b_dir[30] ? mux_port_b_out[30]:1'bz; 
assign port_b[31] = port_b_dir[31] ? mux_port_b_out[31]:1'bz; 
`endif

wire main_clk, internal_clk, pll_clk;

`ifdef SIMULATOR
assign pll_clk = clk_in;
`endif
`ifdef LATTICE_MACHXO2
assign pll_clk = clk_in;
`endif

`ifdef ALTERA_CV
pll_altera pll0(
		.refclk(clk_in),   //  refclk.clk
		.rst(1'b0),      //   reset.reset
		.outclk_0(pll_clk), // outclk0.clk
		.locked()    //  locked.export
	);
`endif

`ifdef HW_DEBUG
reg [5:0] divider;

always @(posedge clk_in)
	begin
		if (divider == 6'd49)
			divider <= 6'd0;
		else
			divider <= divider + 4'h1;
	end
	
assign main_clk = divider < 6'd25; // 1 MHz 50%duty cicle clock

// we transmit debug info @ 1 Mbit, we need 80 characters
// that means 16 ticks per character, the CPU clock is then slow :)
`else
assign main_clk = pll_in;
`endif

wire [31:0] hub_data_to_cog_0, hub_data_to_hub_0;
wire [`HUB_MEM_WIDTH-1:0] hub_mem_addr_0;
wire [1:0] hub_mem_size_0;
wire hub_data_rdy_0, hub_mem_ack_0;
wire [4:0] hub_op_0;
wire cog_reset_0;

wire [31:0] hub_data_to_cog_1, hub_data_to_hub_1;
wire [`HUB_MEM_WIDTH-1:0] hub_mem_addr_1;
wire [1:0] hub_mem_size_1;
wire hub_data_rdy_1, hub_mem_ack_1;
wire [4:0] hub_op_1;
wire cog_reset_1;
wire [95:0] debug_data_cog_0;
wire debug_data_valid_0;

/* Debug interface
 * if hw-debug is enabled a stream of 96 bits is sent on every WBack state.
 * This debug is only for COG 0 for the time being 
 *
 * Format
 *
 * -PC- -OPCODE- HUB_ADDR HUB_DATA
 * 0000 00000000   0000   00000000
 */
 
`ifdef HW_DEBUG

debug debuguint(
	.clk_in(), // main tick
	.clk_tx_in(main_clk), // uart transmitter tick, 1 MHz
	.new_cycle_in(), // assrted when we have to send the info
	.debug_data_in(debug_data_cog_0),
	
	.uart_tx_o(debug_data_o)
	);


reg [95:0] debug_sr;
reg [8:0] debug_cnt;

assign internal_clk = (debug_cnt == 9'h00) & main_clk; // one tick every 512 clocks

always @(posedge main_clk)
	begin
		debug_cnt <= debug_cnt + 7'd1;
	end

/*
assign debug_data_o = debug_sr[95];
// debug state machine
reg [6:0] debug_cnt;
wire debug_cs;
assign internal_clk = debug_cnt == 7'h01; // one tick every 128 clocks

assign debug_cs = (debug_cnt >= 7'd8) && (debug_cnt < 7'd104);
assign debug_cs_o = debug_cs;
assign debug_clk_o = main_clk & debug_cs;
always @(posedge main_clk)
	begin
		debug_cnt <= debug_cnt + 7'd1;
		if (debug_data_valid_0)
			begin
				if (debug_cnt == 7'd7)
					debug_sr <= debug_data_cog_0; // loads data in shift register
				if (debug_cs)
					begin
						debug_sr <= debug_sr << 1;
					end
			end
	end
*/

`else
assign internal_clk = main_clk; // clock for clock
`endif

ACog cog0(
	.clk_in(internal_clk),
	.reset_in(cog_reset_0),	
	.CNT_in(CNT),
	// debug
	.debug_data_o(debug_data_cog_0),
	.debug_data_valid_o(debug_data_valid_0),
	// Ports access 
	.port_a_in(port_a_in),
	.port_a_o(port_a_o_0),
	.port_a_dir_o(port_a_dir_o_0)
`ifdef WITH_PORTB	
	,.port_b_in(port_b_in),
	.port_b_o(port_b_o_0),
	.port_b_dir_o(port_b_dir_o_0)
`endif
	// HUB access 
	,
	.hub_op_o(hub_op_0),
	.hub_addr_o(hub_mem_addr_0),
	.hub_data_in(hub_data_to_cog_0),
	.hub_data_rdy_o(hub_data_rdy_0),
	.hub_sz_o(hub_mem_size_0),
	.hub_data_o(hub_data_to_hub_0),
	.hub_ack_in(hub_mem_ack_0)
	);
`ifdef TWO_COGS
ACog cog1(
	.clk_in(internal_clk),
	.reset_in(cog_reset_1),	
	.CNT_in(CNT),
	// Ports access 
	.port_a_in(port_a_in),
	.port_a_o(port_a_o_1),
	.port_a_dir_o(port_a_dir_o_1)
`ifdef WITH_PORTB
	,.port_b_in(port_b_in),
	.port_b_o(port_b_o_1),
	.port_b_dir_o(port_b_dir_o_1)
`endif
	
	// HUB access 
	,
	.hub_op_o(hub_op_1),
	.hub_addr_o(hub_mem_addr_1),
	.hub_data_in(hub_data_to_cog_1),
	.hub_data_rdy_o(hub_data_rdy_1),
	.hub_sz_o(hub_mem_size_1),
	.hub_data_o(hub_data_to_hub_1),
	.hub_ack_in(hub_mem_ack_1)
	
	);
`endif

HUB hub(
	.clk_in(internal_clk),
	.reset_in(reset_in),
	
	/* Cog 0 */
	.hub_op_0_in(hub_op_0),
	.hub_mem_addr_0_in(hub_mem_addr_0), /* Address */
	.hub_mem_data_0_in(hub_data_to_hub_0),	/* Write data is left aligned */
	.hub_mem_size_0_in(hub_mem_size_0), /* 00: byte, 01: word, 10: long */
	.hub_data_rdy_0_in(hub_data_rdy_0), /* Read request */
	.hub_mem_ack_0_o(hub_mem_ack_0),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_0_o(hub_data_to_cog_0),
	.hub_cog_reset_0_o(cog_reset_0),

	/* Cog 1 */
	.hub_op_1_in(hub_op_1),
	.hub_mem_addr_1_in(hub_mem_addr_1), /* Address */
	.hub_mem_data_1_in(hub_data_to_hub_1),	/* Write data is left aligned */
	.hub_mem_size_1_in(hub_mem_size_1), /* 00: byte, 01: word, 10: long */
	.hub_data_rdy_1_in(hub_data_rdy_1), /* Read request */
	.hub_mem_ack_1_o(hub_mem_ack_1),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_1_o(hub_data_to_cog_1),
	.hub_cog_reset_1_o(cog_reset_1),
	/* Cog 2 */
	.hub_op_2_in(5'b0),
	.hub_mem_addr_2_in(), /* Address */
	.hub_mem_data_2_in(),	/* Write data is left aligned */
	.hub_mem_size_2_in(2'b0), /* 00: byte, 01: word, 10: long */
	.hub_data_rdy_2_in(1'b0), /* Read request */
	.hub_mem_ack_2_o(),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_2_o(),
	.hub_cog_reset_2_o(),
	/* Cog 3 */
	.hub_op_3_in(5'b0),
	.hub_mem_addr_3_in(), /* Address */
	.hub_mem_data_3_in(),	/* Write data is left aligned */
	.hub_mem_size_3_in(2'b0), /* 00: byte, 01: word, 10: long */
	.hub_data_rdy_3_in(1'b0), /* Read request */
	.hub_mem_ack_3_o(),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_3_o(),
	.hub_cog_reset_3_o()
);


/* Global counter */
GblCounter gblcnt(
	.clk_in(internal_clk),
	.reset_in(reset_in),
	
	.CNT_o(CNT)
	);
initial
	begin
`ifdef HW_DEBUG
	$display("Compiled with debug support");
	debug_cnt = 0;
	divider = 0;
`endif
`ifdef ALTERA_CV
	$display("Compiled for Altera Cyclone V");
`endif
`ifdef LATTICE_MACHXO
	$display("Compiled for LAttice MachXO2");
`endif
`ifdef SIMULATOR
	$display("Compiled for Simulation");
`endif

	end
endmodule

module debug(
	input wire clk_in, // main tick
	input wire clk_tx_in, // uart transmitter tick
	input new_cycle_in, // assrted when we have to send the info
	input wire [95:0] debug_data_in,
	
	output wire uart_tx_o
	);
	
reg [95:0] data;
reg [8:0] state;
reg [7:0] uart_data;
reg transmit, transmission_started, transmission_done, old_transmission_done;
wire uart_en;
assign uart_en = (state[3:0] == 4'h2) & (state [ 8:4] > 7'd1) & (state [ 8:4] <= 7'd31); // transmission

wire [7:0] hex = (data[95:92] > 4'h9) ? 8'd55 + data[95:92]:{ 4'h3, data[95:92]};

uart_tx tx(
	.clk_in(clk_tx_in),
	.data_in(uart_data),
	.en_in(uart_en),
	.tx_o(uart_tx_o)
	);

/*
always @(posedge clk_in)
	begin
		if (new_cycle_in)
			transmit <= 1'b1;
		old_transmission_done <= transmission_done
		if ((!old_transmission_done) & transmission_done) // on the rising edge
			transmit <= 1'b0;
	end
*/
always @(posedge clk_tx_in) // we do the work on the slow clock
	begin
				state <= state + 9'd1;
				case (state[ 8:4])
					5'd1: begin uart_data <= 8'd10; data <= debug_data_in; end
					5'd2: begin uart_data <= hex; data <= data << 4; end
					5'd3: uart_data <= 8'd32;
					5'd4: begin uart_data <= hex; data <= data << 4; end // PC
					5'd5: begin uart_data <= hex; data <= data << 4; end
					5'd6: begin uart_data <= hex; data <= data << 4; end
					5'd7: uart_data <= 8'd32;
					5'd9:  begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd10: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd11: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd12: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd13: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd14: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd15: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd16: begin uart_data <= hex; data <= data << 4; end // OPCODE
					5'd17: uart_data <= 8'd32;
					5'd19: begin uart_data <= hex; data <= data << 4; end // HUB ADDR
					5'd20: begin uart_data <= hex; data <= data << 4; end // HUB ADDR
					5'd21: begin uart_data <= hex; data <= data << 4; end // HUB ADDR
					5'd22: begin uart_data <= hex; data <= data << 4; end // HUB ADDR
					5'd23: uart_data <= 8'd32;
					5'd24: begin uart_data <= hex; data <= data << 4; end // HUB DATA
					5'd25: begin uart_data <= hex; data <= data << 4; end 
					5'd26: begin uart_data <= hex; data <= data << 4; end 
					5'd27: begin uart_data <= hex; data <= data << 4; end 
					5'd28: begin uart_data <= hex; data <= data << 4; end 
					5'd29: begin uart_data <= hex; data <= data << 4; end 
					5'd30: begin uart_data <= hex; data <= data << 4; end 
					5'd31: begin uart_data <= hex; data <= data << 4; end 
				endcase

	end

initial
	state = 0;
endmodule

module uart_tx(
	input wire clk_in,
	input wire [7:0] data_in,
	input wire en_in,
	output wire tx_o
	);
	
reg [3:0] state;
reg [7:0] data;
assign tx_o = (state == 1) ? 1'b1:state[3] ? data[0]:1'b0;

always @(posedge clk_in)
	begin
		case (state)
			0: if (en_in) state <= 4'h1;
			1: begin data <= data_in; state <= 4'h8; end
			8, 9, 10, 11, 12, 13, 14, 15: 
				begin
					state <= state + 4'h1;
					data <= data >> 1;
				end
		endcase
	end
	
initial
	state = 0;
	
endmodule

	