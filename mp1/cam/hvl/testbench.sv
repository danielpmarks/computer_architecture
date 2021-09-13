import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
    itf.rw_n <= 0;
    itf.valid_i <= 1;
    itf.key <= key;
    itf.val_i <= val;
    ##1;
    itf.valid_i <= 0;
endtask

task read(input key_t key, output val_t val);
    itf.rw_n <= 1;
    itf.valid_i <= 1;
    itf.key <= key;
    @(tb_clk)
    itf.valid_i <= 0;  
    val <= itf.val_o;
    ##1;
    //$display("val_o: %d, val: %d", itf.val_o, val);
endtask

val_t read_out;

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    
    //Test 1
    for(int i = 0; i < 16; i++) begin
        write(i, i);    //Write key as both key and value
    end

    //Test 2
    for(int i = 8; i < 16; i++) begin
        read(i, read_out);
        assert(itf.val_o == read_out) else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, read_out);
        end
    end

    reset();

    //Write new values to CAM
    write(0, 0);
    write(0, 1);

    reset();
    //Read value on consecutive cycles
    write(0, 0);
    read(0, read_out);

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
