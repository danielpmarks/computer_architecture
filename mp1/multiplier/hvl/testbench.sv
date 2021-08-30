import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    for(int i = 0; i <= 8'hFF; ++i) begin
		for(int j = 0; j <= 8'hFF; ++j) begin
			@(tb_clk iff itf.rdy)
			itf.multiplicand 	<= i;
			itf.multiplier 	    <= j;
			itf.start 			<= 1;
			
			##(1);
			
			itf.start 			<= 0;
			
			@(tb_clk iff itf.done);
			
			assert (itf.product == i * j) 
							else begin
                                $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
                                report_error (BAD_PRODUCT);
                            end
            
            assert (itf.rdy == 1) else begin
                $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
                report_error (NOT_READY);
            end


			
		end
	end

    reset();

    for(int i = 0; i < $size(run_states); i++) begin
        itf.start <= 1;
        ##1;
        itf.start <= 0;

        @(tb_clk iff itf.mult_op == run_states[i])
        itf.start <= 1;
        ##1;
        itf.start <= 0;
        
    end

    reset();

    for(int i = 0; i < $size(run_states); i++) begin
        itf.start <= 1;
        ##1
        itf.start <= 0;

        @(tb_clk iff itf.mult_op == run_states[i])
        reset();
        assert(itf.rdy == 1)
            else begin
                $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
                report_error (NOT_READY);
            end
    end

    reset();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
