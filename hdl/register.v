`timescale 1ns / 1ps
/*
    CocoFLASH - TANDY Color Computer 1,2,3 8MiB FLASH ROM cartridge
                with Orchestra 90 emulation

    Copyright Jim Brain and RETRO Innovations, 2015-2016

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    register.v: Helper function implementing variable width data register

*/

//////////////////////////////////////////////////////////////////////////////////
// Company:          RETRO Innovations
// Engineer:         Jim Brain
// 
// Create Date:      23:52:36 12/08/2013 
// Design Name:      CocoFLASH
// Module Name:      register 
// Project Name:     CocoFLASH
// Target Devices:   any
// Tool versions:    ISE 13
//////////////////////////////////////////////////////////////////////////////////
`ifndef _register
`define _register
module register(clock, reset, enable, d, q);

parameter WIDTH = 8 ;
parameter RESET = 0 ;

input clock;
input reset;
input enable;
input [WIDTH-1:0] d;
output [WIDTH-1:0] q;
reg [WIDTH-1:0] q;
initial q = RESET;

always @ (negedge clock, posedge reset)
  begin
  if(reset)
		q <= RESET;
  else if(enable)
	   q <= d;
  end
endmodule
`endif
