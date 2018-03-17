// Diseño: Calculadora simple implementable
// Descripción: Módulos principales de la calculadora
// Autor: Jorge Juan-Chico <jjchico@gmail.com>
// Fecha: 2018-03-09

////////////////////////////////////////////////////////////////////////////////
// This file is free software: you can redistribute it and/or modify it under //
// the terms of the GNU General Public License as published by the Free       //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version. See <http://www.gnu.org/licenses/>.                     //
////////////////////////////////////////////////////////////////////////////////

//
// Unidad de datos
//
// Se diseñan todos los componentes de la ruta de datos en un
// mismo módulo.

// Operaciones ALU
`define ADD  2'd0   // suma
`define TRA  2'd1   // transfiere entrada A
`define SUB  2'd2   // resta
`define TRB  2'd3   // transfiere entrada B

module calculator_dp ();

endmodule // calculator_dp

//
// Unidad de control
//
/*
    Operación:

    En el estado inicial:
        * load: a <- in; b <- a
        * calc: calcula la operación dada por in

    Operaciones:
        * in[0] (ADD):  a <- a + b
        * in[1] (SUB):  a <- a - b
        * in[2] (BTOA): a <- b
        * in[3] (ATOB): b <- a

    Diseño:
        * Tres procedimientos: cambios de estado, próximo estado y salida.
        * Máquina de Moore
*/

module calculator_ctl ();

endmodule // calculator_ctl

//
// Caculadora completa
//
// Simplemente se conectan la unidad de datos y de control

module calculator ();

endmodule // calculator
