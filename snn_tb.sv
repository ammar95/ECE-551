module snn_tb();

logic clk, sys_rst_n,uart_rx,uart_tx;
logic [7:0] led;

reg [0:0] mem[0:900]; // 16-bit wide 256 entry ROM
initial
$readmemh("ram_input_contents_sample_0.txt",mem);



//snn iDUT(clk, sys_rst_n, led, uart_tx, uart_rx);

initial begin
	clk = 0;
	sys_rst_n = 0;
	# 20 sys_rst_n = 1;
end

always #5 clk = ~clk;


endmodule


// logic curr;
// parameter EOF = -1;
// integer file_handle,error,indx;
// reg signed [15:0] wide_char;
// reg [7:0] mem[0:900];
// reg [639:0] err_str;
// initial begin
	// indx=0;
	// file_handle = $fopen("ram_input_contents_sample_0.txt","r");
	// error = $ferror(file_handle,err_str);
	// if (error==0) begin
		// wide_char = 16'h0000;
		// while (wide_char!=EOF) begin
			// wide_char = $fgetc(file_handle);
			// mem[indx] = wide_char[7:0];
			// $write("%c",mem[indx]);
			// if (wide_char != 8'h0a)
			// curr = wide_char[0:0];
			// #5 indx = indx + 1;
		// end
	// end
	// else $display("Can't open file");
	// $fclose(file_handle);
// end
