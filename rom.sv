module rom (addr,clk,q);
	parameter ADDR_WIDTH = 3;
	parameter DATA_WIDTH = 3;
	parameter [30*8:1]file = "FILE_NAME";
	
	input [(ADDR_WIDTH-1):0] addr;
	input clk;
	output reg [(DATA_WIDTH-1):0] q;
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
	
	initial begin
		readmemh(file, rom);
	end
	
	always @ (posedge clk) begin
		q <= rom[addr];
	end
	
endmodule 
