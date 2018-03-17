// Diseño: Calculadora simple implementable
// Descripción: Sistema de la calculadora. Conexión a controlador 7 segmentos.
// Autor: Jorge Juan-Chico <jjchico@gmail.com>
// Fecha: 2018-03-09

////////////////////////////////////////////////////////////////////////////////
// This file is free software: you can redistribute it and/or modify it under //
// the terms of the GNU General Public License as published by the Free       //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version. See <http://www.gnu.org/licenses/>.                     //
////////////////////////////////////////////////////////////////////////////////

module calc_sys (
    input wire clk,         // señal de reloj
    input wire reset,       // señal de reset
    input wire load,	    // señal de carga de dato
    input wire calc,        // señal de comienzo de operación
    input wire [7:0] in,    // entrada de datos y código de operación
    output wire ready,      // indicador de listo para operar
    output wire [0:6] seg,  // salida para visor 7-segmentos
    output wire [3:0] an,   // salida para visor 7-segmentos
    output wire dp          // salida para visor 7-segmentos
    );

    wire [7:0] calc_out;

    calculator #(.W(8)) calculator(
        .clk(clk),
        .reset(reset),
        .load(load),
        .calc(calc),
        .in(in),
        .ready(ready),
        .out(calc_out));

    seg7_4d_ctrl_dec_tc #(.CDBITS(18)) seg7_4d_ctrl_dec_tc(
        .clk(clk),
        .d(calc_out),
        .dp_in(4'b0000),
        .seg(seg),
        .select(an),
        .dp(dp));

endmodule
