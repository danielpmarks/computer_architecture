module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic reading, next_reading, writing, next_writing;
int count;

always_ff @(posedge clk) begin
    reading <= next_reading;
    writing <= next_writing;
    
    count <= 0;
    //Read operation
    if(reset_n == 0) begin
        reading <= 0;
        count <= 0;
    end else if(reading) begin
        if(resp_i == 1) begin
            line_o <= {burst_i, line_o[255:64]};
        end
    end else if(writing) begin
        if(resp_i == 1) begin
            count <= count + 1;
        end
    end
end

always_comb begin 
    next_reading = read_i || (reading && resp_i);
    next_writing = write_i || (writing && resp_i);
    address_o = address_i;
    resp_o = (!read_i || !write_i) && !resp_i && !resp_o;
    read_o = read_i || reading;
    write_o = write_i || writing;

    if(reset_n == 0) begin
        read_o = 0;
        write_o = 0;
    end else if (writing && resp_i) begin
        burst_o = line_i[count * 64 +: 64];
    end
    
end


endmodule : cacheline_adaptor
