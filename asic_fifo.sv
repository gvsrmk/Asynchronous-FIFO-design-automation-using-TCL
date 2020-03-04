// RTL Taken from:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf

// Top module:
module asic_fifo #(parameter DSIZE = 8, parameter ASIZE = 10)             
	(output [DSIZE-1:0] rdata,
	output wfull,
	output rempty,
	input [DSIZE-1:0] wdata_in,
	input winc, wclk, wclk2x, wrst_n,
	input rinc, rclk, rrst_n);
	wire [ASIZE-1:0] waddr, raddr;
	wire [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
	
	reg [DSIZE-1:0] wdata;

	always @(posedge wclk2x or negedge wrst_n)
	 	if (!wrst_n) {wdata} <= 0;
 		else wdata <= wdata_in;

sync_r2w sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr),
	.wclk(wclk), .wrst_n(wrst_n));

sync_w2r sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr),
	.rclk(rclk), .rrst_n(rrst_n));

fifomem #(DSIZE, ASIZE) fifomem
	(.rdata(rdata), .wdata(wdata),
	.waddr(waddr), .raddr(raddr),
	.wclken(winc), .wfull(wfull),
	.wclk(wclk));

rptr_empty #(ASIZE) rptr_empty
	(.rempty(rempty),
	.raddr(raddr),
	.rptr(rptr), .rq2_wptr(rq2_wptr),
	.rinc(rinc), .rclk(rclk),
	.rrst_n(rrst_n));

wptr_full #(ASIZE) wptr_full
	(.wfull(wfull), .waddr(waddr),
	.wptr(wptr), .wq2_rptr(wq2_rptr),
	.winc(winc), .wclk(wclk),
	.wrst_n(wrst_n));

endmodule


// ------------------------------------------------------------------
module fifomem #(parameter DSIZE = 8, // Memory data word width
	parameter ASIZE = 10) // Number of mem address bits
	(output [DSIZE-1:0] rdata,
	input [DSIZE-1:0] wdata,
	input [ASIZE-1:0] waddr, raddr,
	input wclken, wfull, wclk);

	// RTL Verilog memory model
	localparam DEPTH = 1<<ASIZE;
	reg [DSIZE-1:0] mem [0:DEPTH-1];
	assign rdata = mem[raddr];
	always @(posedge wclk)
	if (wclken && !wfull) mem[waddr] <= wdata;

endmodule

// ------------------------------------------------------------------
module sync_r2w #(parameter ASIZE = 10)
	(output reg [ASIZE:0] wq2_rptr,
	input [ASIZE:0] rptr,
	input wclk, wrst_n);
	reg [ASIZE:0] wq1_rptr;
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
		else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
endmodule

// ------------------------------------------------------------------
module sync_w2r #(parameter ASIZE = 10)
	(output reg [ASIZE:0] rq2_wptr,
	input [ASIZE:0] wptr,
	input rclk, rrst_n);
	reg [ASIZE:0] rq1_wptr;
	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;
		else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
endmodule


// ------------------------------------------------------------------
module rptr_empty #(parameter ASIZE = 10)
	(output reg rempty,
	output [ASIZE-1:0] raddr,
	output reg [ASIZE :0] rptr,
	input [ASIZE :0] rq2_wptr,
	input rinc, rclk, rrst_n);
	reg [ASIZE:0] rbin;
	wire [ASIZE:0] rgraynext, rbinnext;
	wire rempty_val;
	//-------------------
	// GRAYSTYLE2 pointer
	//-------------------
	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) {rbin, rptr} <= 0;
	else {rbin, rptr} <= {rbinnext, rgraynext};
	// Memory read-address pointer (okay to use binary to address memory)
	assign raddr = rbin[ASIZE-1:0];
	assign rbinnext = rbin + (rinc & ~rempty);
	assign rgraynext = (rbinnext>>1) ^ rbinnext;
	//---------------------------------------------------------------
	// FIFO empty when the next rptr == synchronized wptr or on reset
	//---------------------------------------------------------------
	assign rempty_val = (rgraynext == rq2_wptr);
	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) rempty <= 1'b1;
	else rempty <= rempty_val;
endmodule


// ------------------------------------------------------------------
module wptr_full #(parameter ASIZE = 10)
	(output reg wfull,
	output [ASIZE-1:0] waddr,
	output reg [ASIZE :0] wptr,
	input [ASIZE :0] wq2_rptr,
	input winc, wclk, wrst_n);
	reg [ASIZE:0] wbin;
	wire [ASIZE:0] wgraynext, wbinnext;
	wire wfull_val;
	// GRAYSTYLE2 pointer
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) {wbin, wptr} <= 0;
		else {wbin, wptr} <= {wbinnext, wgraynext};
	// Memory write-address pointer (okay to use binary to address memory)
	assign waddr = wbin[ASIZE-1:0];
	assign wbinnext = wbin + (winc & ~wfull);
	assign wgraynext = (wbinnext>>1) ^ wbinnext;
	//------------------------------------------------------------------
	// Simplified version of the three necessary full-tests:
	// assign wfull_val=((wgnext[ASIZE] !=wq2_rptr[ASIZE] ) &&
	// (wgnext[ASIZE-1] !=wq2_rptr[ASIZE-1]) &&
	// (wgnext[ASIZE-2:0]==wq2_rptr[ASIZE-2:0]));
	//------------------------------------------------------------------
	assign wfull_val = (wgraynext=={~wq2_rptr[ASIZE:ASIZE-1],
	wq2_rptr[ASIZE-2:0]});
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) wfull <= 1'b0;
		else wfull <= wfull_val;
endmodule
