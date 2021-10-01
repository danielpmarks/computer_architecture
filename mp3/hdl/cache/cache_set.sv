module cache_set #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask
)
( 
    input clk,
    input rst,
    input logic [s_index-1:0] set_idx,
    input logic [s_index-1:0] set_select,
    input logic [s_offset-1:0] offset,
    input logic [s_tag-1:0] tag,
    input logic [s_line-1:0] data_in,
    input logic [s_mask-1:0] mask,
    input logic read,
    input logic write,
    output logic [s_line-1:0] data_out,
    output logic hit,
    output logic dirty,
    output logic [31:0] replace_address
);

logic [s_tag-1:0] tag_0, tag_1;
logic [s_line-1:0] data_in_0, data_in_1, data_out_0, data_out_1;
logic load_tag_0, load_tag_1, load_data_0, load_data_1, load_valid_0, load_valid_1, load_dirty_0, load_dirty_1;
logic valid_in_0, valid_in_1, valid_out_0, valid_out_0;
logic dirty_in_0, dirty_in_1, dirty_out_0, dirty_out_1;
logic lru_in, lru_out, load_lru;

register #(.width(1)) LRU_reg(.*, .load(load_lru), .in(lru_set), .out(lru_out));

/* Tag Registers */
register #(.width(s_tag)) tag_0_reg(.*, .load(load_tag_0), .in(tag), .out(tag_0)); 
register #(.width(s_tag)) tag_1_reg(.*, .load(load_tag_1), .in(tag), .out(tag_1)); 

/* Data Registers */
register #(.width(s_line)) data_0_reg(.*, .load(load_tag_0), .in(data_in), .out(data_out_0));
register #(.width(s_line)) data_1_reg(.*, .load(load_tag_1), .in(data_in), .out(data_out_1));

/* Valid Registers */
register #(.width(s_line)) valid_0_reg(.*, .load(load_valid_0), .in(valid_in_0), .out(valid_out_0));
register #(.width(s_line)) valid_1_reg(.*, .load(load_valid_1), .in(valid_in_1), .out(valid_out_1));

/* Dirty Registers */
register #(.width(s_line)) dirty_0_reg(.*, .load(load_dirty_0), .in(dirty_in_0), .out(dirty_out_0));
register #(.width(s_line)) dirty_1_reg(.*, .load(load_dirty_1), .in(dirty_in_1), .out(dirty_out_1));

always_comb begin
    data_out = 0;
    load_lru = 0;
    load_data_0 = 0;
    load_data_1 = 0;
    load_valid_0 = 0;
    load_valid_1 = 0;
    load_dirty_0 = 0;
    load_dirty_1 = 0;
    load_tag_0 = 0;
    load_tag_1 = 0;
    replace_address = 0;
    hit = 0;
    if(set_idx == set_select) begin
        if(tag == tag_0) begin
            // Hit - read from cacheline for read op and write to cacheline for write op
            hit = 1;
            if(read) begin
                data_out = data_out_0;
                dirty = dirty_out_0;
            end
            else if(write) begin
                load_data_0 = 1;
                load_lru = 1;
                load_dirty = 1;

                data_in_0 = data_in;
                dirty_in_0 = 1;
                lru_in = 1;
            end
        end
        else if(tag == tag_1) begin
            // Hit - read from cacheline for read op and write to cacheline for write op
            
            hit = 1;
            if(read) begin
                data_out = data_out_1;
                dirty = dirty_out_1;
            end
            else if(write) begin
                load_data_1 = 1;
                load_lru = 1;
                load_dirty = 1;

                data_in_1 = data_in;
                dirty_in_1 = 1;
                lru_in = 1;
            end
        end
        else begin
            // Miss - replace least recent cacheline with data from pmem
            hit = 0;
            //If way 0 is open, fill this first
            if(valid_out_0 == 0) begin
                //Wait for write signal
                if(write == 1) begin
                    load_data_0 = 1;
                    load_valid_0 = 1;
                    load_dirty_0 = 1;
                    load_tag_0 = 1;
                    load_lru = 1;

                    valid_in_0 = 1;
                    dirty_in_0 = 0;
                    lru_in = 1;
                end
            end
            //If way 0 is full but way 1 is open, fill way 1
            else if (valid_out_1 == 0) begin
                //Wait for write signal
                if(write == 1) begin
                    load_data_1 = 1;
                    load_valid_1 = 1;
                    load_dirty_1 = 1;
                    load_tag_1 = 1;
                    load_lru = 1;

                    valid_in_0 = 1;
                    dirty_in_0 = 0;
                    lru_in = 0;
                end
            end
            //Neither way is open, replace the least recent way
            else begin
                if(lru_out == 0) begin
                    //Read data from way 0 to store to memory
                    data_out = data_out_0;
                    //Set dirty out
                    dirty = dirty_out_0;
                    //Output the address of this cacheline to store into pmem
                    replace_address = {tag_0, set_select, 5'd0};
                    //Wait for write signal to store data from pmem
                    if(write == 1) begin
                        load_data_0 = 1;
                        load_valid_0 = 1;
                        load_dirty_0 = 1;
                        load_tag_0 = 1;
                        load_lru = 1;

                        valid_in_0 = 1;
                        dirty_in_0 = 0;
                        lru_in = 1;
                    end
                end
                else begin
                    //Read data from way 0 to store to memory
                    data_out = data_out_1;
                    //Set dirty out
                    dirty = dirty_out_1;
                    //Output the address of this cacheline to store into pmem
                    replace_address = {tag_1, set_select, 5'd0};
                    //Wait for write signal to store data from pmem
                    if(write == 1) begin
                        load_data_1 = 1;
                        load_valid_1 = 1;
                        load_dirty_1 = 1;
                        load_tag_1 = 1;
                        load_lru = 1;

                        valid_in_0 = 1;
                        dirty_in_0 = 0;
                        lru_in = 0;
                    end
                end
            end
        end
    end
end



register #(.width())





endmodule