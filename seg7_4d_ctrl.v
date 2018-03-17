// Design: display_ctrl
// Description: Four-digit, 7-segment display controller for KW4-281 devices
// Author: Jorge Juan <jjchico@gmail.com>
// Date: 2018-03-09 (original)

////////////////////////////////////////////////////////////////////////////////
// This file is free software: you can redistribute it and/or modify it under //
// the terms of the GNU General Public License as published by the Free       //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version. See <http://www.gnu.org/licenses/>.                     //
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// Display controller                                                   //
//////////////////////////////////////////////////////////////////////////

/*
    Display controllers for KW4-281 4-digit 7-segment display devices tipically
    found in FPGA and microcontroller boards.
*/

// Binary to BCD 8-bit converter, 2 1/2 BCD digits
//
// BCD output
//   d[9:8]  hundreds
//   d[7:4]  tens
//   d[3:0]  units

module bin_to_bcd_8 (
    input wire [7:0] bin,   // binary input
    output reg [9:0] dec    // BCD output
    );

    reg [7:0] b;     // local copy of b
    integer i;        // loop counter

    always @* begin
        b = bin;
        dec = 10'd0;

        for (i=0; i<7; i=i+1) begin
            // shift left d and bi
            {dec,b} = {dec,b} << 1;

                if (dec[7:4] > 4)        // check tens
                    dec[7:4] = dec[7:4] + 4'd3;
                if (dec[3:0] > 4)        // check units
                    dec[3:0] = dec[3:0] + 4'd3;
        end
        {dec,b} = {dec,b} << 1;  // shift once more
    end
endmodule // bin_to_bcd_8

//
// Raw 7 segment display controller with selectable on-digits and sign symbol
//

module seg7_4d_ctrl_raw #(
    parameter CDBITS = 18,      // clock divider bits
                                // Clock freq.  bits
                                //       12MHz  16
                                //       25MHz  17
                                //       50MHz  18
                                //      100MHz  19
                                //      200MHz  20  etc.
    parameter POL = 0,          // polarization
                                //   0 - common anode (output active low)
                                //   1 - common cathode (output active high)
    parameter SELECT_POL = 0    // output select signal polarization
                                //   0 - active low
                                //   1 - active high
    )(
    input wire clk,             // system clock
    input wire [15:0] d,        // display digits, from left to right
    input wire [3:0] on_mask,   // on-digits mask (active high)
    input wire [3:0] dp_in,     // decimal point vector (active high)
    input wire [3:0] sign_mask, // sign simbol vector (active high)
    output wire [0:6] seg,      // 7-segment output
    output wire [3:0] select,   // select output (controls common anode/cathode)
    output wire dp              // decimal point output
    );

    // Internal signals
    reg [CDBITS-1:0] counter = 0;   // clock divider counter
    wire [1:0] csel;                // clock divider select output
    reg [3:0] digit;                // selected input digit
    reg [0:6] iseg;                 // internal 7-segment converter output
    reg [3:0] iselect;              // internal select
    reg [3:0] idp;                  // internal dp

    // 7-segment converter function
    function [0:6] sseg_convert(
        input [3:0] d
    );
        case (d)
        4'h0: sseg_convert = 7'b1111110;
        4'h1: sseg_convert = 7'b0110000;
        4'h2: sseg_convert = 7'b1101101;
        4'h3: sseg_convert = 7'b1111001;
        4'h4: sseg_convert = 7'b0110011;
        4'h5: sseg_convert = 7'b1011011;
        4'h6: sseg_convert = 7'b1011111;
        4'h7: sseg_convert = 7'b1110000;
        4'h8: sseg_convert = 7'b1111111;
        4'h9: sseg_convert = 7'b1111011;
        4'ha: sseg_convert = 7'b1110111;
        4'hb: sseg_convert = 7'b0011111;
        4'hc: sseg_convert = 7'b1001110;
        4'hd: sseg_convert = 7'b0111101;
        4'he: sseg_convert = 7'b1001111;
        4'hf: sseg_convert = 7'b1000111;
        default: sseg_convert = 7'hxx;
        endcase
    endfunction

    // Clock divider
    always @(posedge clk)
        counter = counter + 1;

    // clock divider select generation
    assign csel = counter[CDBITS-1:CDBITS-2];

    // select input digit
    always @*
        case (csel)
        2'd0: digit = d[3:0];
        2'd1: digit = d[7:4];
        2'd2: digit = d[11:8];
        2'd3: digit = d[15:12];
        endcase

    // output calculations
    always @* begin
        // output anode/cathode selector
        iselect = 4'h0;
        iselect[csel] = on_mask[csel];

        // output dedimal point
        idp = dp_in[csel];

        // 7-segment output
        if(on_mask[csel])
            if(sign_mask[csel])
                iseg = 7'b0000001;
            else
                iseg = sseg_convert(digit);
        else
            iseg = 0;
    end

    // output generation
    assign seg = POL ? iseg : ~iseg;
    assign select =  SELECT_POL ? iselect : ~iselect;
    assign dp = POL ? idp : ~idp;

endmodule // seg7_4d_ctrl_raw

//
// Digit padding
//
// Turn-off left-most cero digits and ajust sign if necessary
//
// Input:
//      [15:0] x : Input digits
//             s : sign
// Output
//      [3:0] on_mask: on digit mask
//      [3:0] sign: sign symbol mask

module seg7_4d_pad (
    input wire [15:4] d,        // input digits (only three most significant)
    input wire sign,            // input sign (0 +, 1 -)
    output reg [3:0] on_mask,   // on-digits mask
    output reg [3:0] sign_mask  // sign mask
);

    // split input digits
    wire [3:0] d3, d2, d1, d0;
    reg [4:0] sign_mask_i;
    reg [4:0] on_mask_i;

    assign d3 = d[15:12];
    assign d2 = d[11:8];
    assign d1 = d[7:4];

    always @* begin
        sign_mask_i = {sign,4'b0};             // initial sign mask
        on_mask_i = {sign,4'b1111};            // initial on mask
        if(d3 == 4'd0) begin                   // off 3rd digit if zero, etc.
            sign_mask_i = sign_mask_i >> 1;
            on_mask_i = on_mask_i >> 1;
            if (d2 == 4'd0) begin
                sign_mask_i = sign_mask_i >> 1;
                on_mask_i = on_mask_i >> 1;
                if (d1 == 4'd0) begin
                    sign_mask_i = sign_mask_i >> 1;
                    on_mask_i = on_mask_i >> 1;
                end
            end
        end

        if(sign_mask_i[4] == 1'b1) begin    // sign is out of the display
            sign_mask = 4'b1111;            // output error pattern "----"
            on_mask = 4'b1111;
        end
        else begin                          // no sign or there is room enough
            sign_mask = sign_mask_i[3:0];
            on_mask = on_mask_i[3:0];
        end
    end
endmodule // seg7_4d_pad

//
// sign-magnitude, hexadecimal 7 segment display controller
//

module seg7_4d_ctrl_hex #(
    parameter CDBITS = 18,      // clock divider bits
                                // Clock freq.  bits
                                //       12MHz  16
                                //       25MHz  17
                                //       50MHz  18
                                //      100MHz  19
                                //      200MHz  20  etc.
    parameter POL = 0,          // polarization
                                //   0 - common anode (output active low)
                                //   1 - common cathode (output active high)
    parameter SELECT_POL = 0    // output select signal polarization
                                //   0 - active low
                                //   1 - active high
    )(
    input wire clk,             // system clock
    input wire [15:0] d,        // display digits, from left to right
    input wire [3:0] dp_in,     // decimal point input vector
    input wire sign,            // sign
    output wire [0:6] seg,      // 7-segment output
    output wire [3:0] select,   // select output (controls common anode/cathode)
    output wire dp              // decimal point output vector
);

    wire [3:0] on_mask;
    wire [3:0] sign_mask;

    seg7_4d_ctrl_raw #(
        .CDBITS(CDBITS),
        .POL(POL),
        .SELECT_POL(SELECT_POL)
    ) seg7_4d_ctrl_raw (
        .clk(clk),
        .d(d),
        .on_mask(on_mask),
        .dp_in(dp_in),
        .sign_mask(sign_mask),
        .seg(seg),
        .select(select),
        .dp(dp)
    );

    seg7_4d_pad seg7_4d_pad (
        .d(d[15:4]),            // input digits
        .sign(sign),            // input sign (0 +, 1 -)
        .on_mask(on_mask),      // on-digits mask
        .sign_mask(sign_mask)
    );
endmodule // seg7_4d_ctrl

//
// two's complement decimal 7 segment display controller
//

module seg7_4d_ctrl_dec_tc #(
    parameter CDBITS = 18,      // clock divider bits
                                // Clock freq.  bits
                                //       12MHz  16
                                //       25MHz  17
                                //       50MHz  18
                                //      100MHz  19
                                //      200MHz  20  etc.
    parameter POL = 0,          // polarization
                                //   0 - common anode (output active low)
                                //   1 - common cathode (output active high)
    parameter SELECT_POL = 0    // output select signal polarization
                                //   0 - active low
                                //   1 - active high
    )(
    input wire clk,             // system clock
    input wire signed [7:0] d,  // signed (two's complement) 8 bit input data
    input wire [3:0] dp_in,     // decimal point input vector
    output wire [0:6] seg,      // 7-segment output
    output wire [3:0] select,   // select output (controls common anode/cathode)
    output wire dp              // decimal point output vector
);

    reg [7:0] bin;
    wire [9:0] dec;
    reg sign;

    always @* begin
        if(d < 0) begin
            bin = -d;
            sign = 1'b1;
        end else begin
            bin = d;
            sign = 1'b0;
        end
    end

    bin_to_bcd_8 bin_to_bcd_8 (
        .bin(bin),
        .dec(dec)
    );

    seg7_4d_ctrl_hex #(
        .CDBITS(CDBITS),
        .POL(POL),
        .SELECT_POL(SELECT_POL)
    ) seg7_4d_ctrl_hex (
        .clk(clk),
        .d({6'd0,dec}),
        .dp_in(dp_in),
        .sign(sign),
        .seg(seg),
        .select(select),
        .dp(dp)
    );
    

endmodule // seg7_4d_ctrl_dec_tc




