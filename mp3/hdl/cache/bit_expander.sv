module bit_expander(input logic [31:0] byte_mask, output logic [255:0] bit_mask, input logic [255:0] cache_data_in,input logic [255:0] data_in, output logic [255:0] data_out);
logic [255:0] neg, pos;
always_comb begin : bit_array_logic
    neg = cache_data_in & (~bit_mask);
    pos = data_in & bit_mask;
    data_out = neg | pos;

    bit_mask = 0;
	 if(byte_mask[31])
        bit_mask[255-:8] = 8'hFF;
    if(byte_mask[30])
        bit_mask[247-:8] = 8'hFF;
    if(byte_mask[29])
        bit_mask[239-:8] = 8'hFF;
    if(byte_mask[28])
        bit_mask[231-:8] = 8'hFF;
    if(byte_mask[27])
        bit_mask[223-:8] = 8'hFF;
    if(byte_mask[26])
        bit_mask[215-:8] = 8'hFF;
    if(byte_mask[25])
        bit_mask[207-:8] = 8'hFF;
    if(byte_mask[24])
        bit_mask[199-:8] = 8'hFF;
    if(byte_mask[23])
        bit_mask[191-:8] = 8'hFF;
    if(byte_mask[22])
        bit_mask[183-:8] = 8'hFF;
    if(byte_mask[21])
        bit_mask[175-:8] = 8'hFF;
    if(byte_mask[20])
        bit_mask[167-:8] = 8'hFF;
    if(byte_mask[19])
        bit_mask[159-:8] = 8'hFF;
    if(byte_mask[18])
        bit_mask[151-:8] = 8'hFF;
    if(byte_mask[17])
        bit_mask[143-:8] = 8'hFF;
    if(byte_mask[16])
        bit_mask[135-:8] = 8'hFF;
    if(byte_mask[15])
        bit_mask[127-:8] = 8'hFF;
    if(byte_mask[14])
        bit_mask[119-:8] = 8'hFF;
    if(byte_mask[13])
        bit_mask[111-:8] = 8'hFF;
    if(byte_mask[12])
        bit_mask[103-:8] = 8'hFF;
    if(byte_mask[11])
        bit_mask[95-:8] = 8'hFF;
    if(byte_mask[10])
        bit_mask[87-:8] = 8'hFF;
    if(byte_mask[9])
        bit_mask[79-:8] = 8'hFF;
    if(byte_mask[8])
        bit_mask[71-:8] = 8'hFF;
    if(byte_mask[7])
        bit_mask[63-:8] = 8'hFF;
    if(byte_mask[6])
        bit_mask[55-:8] = 8'hFF;
    if(byte_mask[5])
        bit_mask[47-:8] = 8'hFF;
    if(byte_mask[4])
        bit_mask[39-:8] = 8'hFF;
    if(byte_mask[3])
        bit_mask[31-:8] = 8'hFF;
    if(byte_mask[2])
        bit_mask[23-:8] = 8'hFF;
    if(byte_mask[1])
        bit_mask[15-:8] = 8'hFF;
    if(byte_mask[0])
        bit_mask[7-:8] = 8'hFF;
end

endmodule