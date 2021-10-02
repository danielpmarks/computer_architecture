import rv32i_types::*;

module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

    logic [31:0] mem_address, mem_wdata, mem_rdata;
    logic [3:0] mem_byte_enable;
    logic mem_read, mem_write, mem_resp;

    logic pmem_read_cache, pmem_write_cache, pmem_resp_cache;

    logic [255:0] line_i, line_o;
    logic [31:0] pmem_address_cache;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu_golden cpu(.*);

// Keep cache named `cache` for RVFI Monitor
cache cache(.*,
    .pmem_rdata(line_o),
    .pmem_wdata(line_i),
    .pmem_resp(pmem_resp_cache),
    .pmem_address(pmem_address_cache),
    .pmem_write(pmem_write_cache),
    .pmem_read(pmem_read_cache)
);

// From MP1
cacheline_adaptor cacheline_adaptor
(
    .*,
    .reset_n(!rst),
    .read_i(pmem_read_cache),
    .write_i(pmem_write_cache),
    .resp_o(pmem_resp_cache),
    .address_i(pmem_address_cache),
    .line_i(line_i),
    .line_o(line_o),

    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3
