module snn(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output logic [7:0] led;	// Drives LEDs of DE0 nano board
	
	input uart_rx;
	output uart_tx;

	logic rst_n;				 	// Synchronized active low reset
	
	logic uart_rx_ff, uart_rx_synch;

	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	/******************************************************
	UART
	******************************************************/
	
	// Declare wires below
	wire tx_start;
	wire [7:0] uart_data;
	wire ram_input_unit_we,ram_input_unit_data,ram_input_unit_out;
	wire [9:0] ram_input_unit_addr;

	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".

	// TODO: fill in the sample #
	ram #(.DATA_WIDTH(1),.ADDR_WIDTH(10),.file(ram_input_contents_sample_?.txt)) 
		ram_input_unit(ram_input_unit_data,ram_input_unit_addr,ram_input_unit_we,clk,ram_input_unit_out);
	
	// TODO: read only during test
	assign ram_input_unit_we = 1'b0;
	assign ram_input_unit_data = 1'b0;
	
	
	
			
	/******************************************************
	LED
	******************************************************/
	assign	led = (tx_start) ? uart_data : led;


endmodule

