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

    spi.v: Simple master SPI implementation

*/

//////////////////////////////////////////////////////////////////////////////////
// Company:          RETRO Innovations
// Engineer:         Jim Brain
// 
// Create Date:      21:30:23 01/28/2016 
// Design Name:      CocoFLASH
// Module Name:      shift_register 
// Project Name:     CocoFLASH
// Target Devices:   any
// Tool versions:    ISE 13
//////////////////////////////////////////////////////////////////////////////////

`ifndef _spi
`define _spi
module spi(
           input clock, 
           input reset, 
           input load, 
           input [7:0]d, 
           output reg [7:0]q, 
           output sck, 
           input miso, 
           output mosi
          );

reg in;
initial q = 0;
reg [3:0]i;
wire run;

initial i[3:0] = 8;

assign mosi = q[7];
assign run = (!i[3]);
assign sck = clock & run;

always @(posedge clock)
begin
  in <= miso;
end

always @(negedge clock or posedge reset)
begin
  if(reset)
  begin
    q <= 0;
	 i <= 8;
  end
  else if(load)
  begin
    q <= d;
	 i <= 0;
  end
  else if(run) 
  begin
    i <= i + 1;
    q <= {q[6:0],in};
  end
end

endmodule

`endif
