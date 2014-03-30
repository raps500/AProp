/* 
 * AProp
 *
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
module AProp(
	input wire clk_in,
	input wire reset_in,
	
	inout wire [31:0] port_a
`ifdef WITH_PORTB
	,inout wire [31:0] port_b
`endif
	);

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

wire main_clk;
assign main_clk = clk_in;

wire [31:0] hub_data_to_cog_0, hub_data_to_hub_0;
wire [`HUB_MEM_WIDTH-1:0] hub_mem_addr_0;
wire [1:0] hub_mem_size_0;
wire hub_mem_read_0, hub_mem_write_0, hub_mem_ack_0;

wire [31:0] hub_data_to_cog_1, hub_data_to_hub_1;
wire [`HUB_MEM_WIDTH-1:0] hub_mem_addr_1;
wire [1:0] hub_mem_size_1;
wire hub_mem_read_1, hub_mem_write_1, hub_mem_ack_1;

ACog cog0(
	.clk_in(main_clk),
	.reset_in(reset_in),	
	// Ports access 
	.port_a_in(port_a_in),
	.port_a_o(port_a_o_0),
	.port_a_dir_o(port_a_dir_o_0)
`ifdef WITHP_ORTB	
	,.port_b_in(port_b_in),
	.port_b_o(port_b_o_0),
	.port_b_dir_o(port_b_dir_o_0)
`endif
	// HUB access 
	,
	.hub_addr_o(hub_mem_addr_0),
	.hub_data_in(hub_data_to_cog_0),
	.hub_read_o(hub_mem_read_0),
	.hub_write_o(hub_mem_write_0),
	.hub_sz_o(hub_mem_size_0),
	.hub_data_o(hub_data_to_hub_0),
	.hub_ack_in(hub_mem_ack_0)
	);
`ifdef TWO_COGS
ACog cog1(
	.clk_in(main_clk),
	.reset_in(reset_in),	
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
	.hub_addr_o(hub_mem_addr_1),
	.hub_data_in(hub_data_to_cog_1),
	.hub_read_o(hub_mem_read_1),
	.hub_write_o(hub_mem_write_1),
	.hub_sz_o(hub_mem_size_1),
	.hub_data_o(hub_data_to_hub_1),
	.hub_ack_in(hub_mem_ack_1)
	
	);
`endif

HUB_Sim hub(
	.clk_in(main_clk),
	.reset_in(reset_in),
	
	/* Cog 0 */
	.hub_mem_addr_0_in(hub_mem_addr_0), /* Address */
	.hub_mem_data_0_in(hub_data_to_hub_0),	/* Write data is left aligned */
	.hub_mem_size_0_in(hub_mem_size_0), /* 00: byte, 01: word, 10: long */
	.hub_mem_read_0_in(hub_mem_read_0), /* Read request */
	.hub_mem_write_0_in(hub_mem_write_0),	/* Write request */
	.hub_mem_ack_0_o(hub_mem_ack_0),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_0_o(hub_data_to_cog_0),
	/* Cog 1 */
	.hub_mem_addr_1_in(hub_mem_addr_1), /* Address */
	.hub_mem_data_1_in(hub_data_to_hub_1),	/* Write data is left aligned */
	.hub_mem_size_1_in(hub_mem_size_1), /* 00: byte, 01: word, 10: long */
	.hub_mem_read_1_in(hub_mem_read_1), /* Read request */
	.hub_mem_write_1_in(hub_mem_write_1),	/* Write request */
	.hub_mem_ack_1_o(hub_mem_ack_1),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_1_o(hub_data_to_cog_1),
	/* Cog 2 */
	.hub_mem_addr_2_in(), /* Address */
	.hub_mem_data_2_in(),	/* Write data is left aligned */
	.hub_mem_size_2_in(2'b0), /* 00: byte, 01: word, 10: long */
	.hub_mem_read_2_in(1'b0), /* Read request */
	.hub_mem_write_2_in(1'b0),	/* Write request */
	.hub_mem_ack_2_o(),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_2_o(),
	/* Cog 3 */
	.hub_mem_addr_3_in(), /* Address */
	.hub_mem_data_3_in(),	/* Write data is left aligned */
	.hub_mem_size_3_in(2'b0), /* 00: byte, 01: word, 10: long */
	.hub_mem_read_3_in(1'b0), /* Read request */
	.hub_mem_write_3_in(1'b0),	/* Write request */
	.hub_mem_ack_3_o(),	/* asserted when data has been written or is ready to be latched */
	.hub_mem_data_3_o()
	);
/* Global counter */
GblCounter gblcnt(
	.clk_in(main_clk),
	.reset_in(reset_in),
	
	.CNT_o()
	);
	
endmodule
