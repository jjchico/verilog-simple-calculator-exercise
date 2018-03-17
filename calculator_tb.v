// Diseño: Calculadora simple implementable
// Descripción: Banco de pruebas de la calculadora
// Autor: Jorge Juan-Chico <jjchico@gmail.com>
// Fecha: 2018-03-09

////////////////////////////////////////////////////////////////////////////////
// This file is free software: you can redistribute it and/or modify it under //
// the terms of the GNU General Public License as published by the Free       //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version. See <http://www.gnu.org/licenses/>.                     //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module test ();

    reg clk;
    reg reset;
    reg load;
    reg calc;
    reg [7:0] in;
    wire ready;
    wire [7:0] out;

    // Circuito bajo test
    calculator #(.W(8)) uut (
        .clk(clk), .reset(reset), .load(load), .calc(calc),
        .in(in), .ready(ready), .out(out));


endmodule
