`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

error_e err;

initial begin
    reset();
    /************************ Your Code Here ***********************/
    //Test 1
    itf.data_i <= 8'd0;
    while(itf.rdy) begin
        @(tb_clk)
        itf.valid_i <= 1;
        @(tb_clk)
        itf.valid_i <= 0;
        itf.data_i <= itf.data_i + 1;
    end

    @(tb_clk)
    itf.data_i <= 0;

    //Test 2
    while(itf.valid_o) begin
        @(tb_clk)
        itf.yumi <= 1;
        assert(itf.data_o == itf.data_i)
            else begin
                $error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I );
                report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end
        @(tb_clk)
        itf.yumi <= 0;
        itf.data_i <= itf.data_i + 1;        
    end
    $display("%d %d", itf.valid_o, itf.rdy);

    //Enqueue one item
    @(tb_clk)
    itf.valid_i <= 1;
    @(tb_clk)
    itf.valid_i <= 0;
    $display("%d %d", itf.valid_o, itf.rdy);

    while(itf.valid_o && itf.rdy) begin
        @(tb_clk)
        itf.valid_i <= 1;
        itf.yumi <= 1;

        @(tb_clk)

        itf.valid_i <= 0;
        itf.yumi <= 0;

        @(tb_clk iff itf.rdy)

        //Push new item to queue
        itf.valid_i <= 1;
        @(tb_clk)
        itf.valid_i <= 0;
    end

    @(tb_clk);
    itf.reset_n <= 0;
    @(posedge itf.clk);
    assert (itf.rdy == 1)  
    else begin
        $error ("%0d: %0t: %s error detected", `__LINE__, $time, RESET_DOES_NOT_CAUSE_READY_O);
        report_error (RESET_DOES_NOT_CAUSE_READY_O);
    end


    
    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

