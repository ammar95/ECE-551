module cnt_async(cnt,clk,rst_n,en);

	parameter bit_length = 5;
	input clk,rst_n,en;		//input clk, active low rst
	output reg[(bit_length-1):0] cnt;		//output counter
	
always @(posedge clk, negedge rst_n)			// positive edge triggered async counter

	if (!rst_n)
		cnt<= 10'h0;		//reset counter on active low reset signal
	else if (en)
		cnt <=cnt+1;		// Move to next state

endmodule

