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

    CocoFLash.v: Main functionality of flash cartridge

*/

//////////////////////////////////////////////////////////////////////////////////
// Company: RETRO Innovations
// Engineer: Jim Brain
// 
// Create Date:    21:22:56 03/27/2015 
// Design Name: CocoFLASH
// Module Name:    CoCoFlash 
// Project Name: 
// Target Devices: XC95144XL
// Tool versions: ISE 13
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module CoCoFlash(
                 input _reset,
                 input e, 
                 input q, 
                 input r_w, 
                 input [15:0]address, 
                 inout [7:0]data, 
                 input _cts, 
                 output _cart, 
                 output [22:0]baddress, 
                 inout [7:0]bdata, 
                 output _we, 
                 output _oe, 
                 input _scs, 
                 inout _slenb, 
                 output _freset, 
                 input [1:0]switch, 
                 output led, 
                 output _ss,
                 output _ss2,
                 output sck, 
                 output mosi, 
                 input miso,
                 output [1:0]_channel,
                 input [3:0]cfg,
                 input reset_long
                );
                
parameter FAM_RS =         4'h1;  // TANDY/RS
parameter ID_OR90 =        4'h1;  // Orchestra 90
parameter VER_OR90 =       4'h2;  // second version

parameter FAM_RI =         4'h2;  // RETRO Innovations
parameter ID_CF =          4'h1;  // CocoFLASH
parameter VER_CF =         4'h1;  // first version

wire [7:0]data_reg;
wire [7:0]data_regc;
wire [7:0]data_reg_or90;
wire [7:0]data_mux;
wire [7:0]data_bank_id;
wire [7:0]data_bank_ver;
wire [10:0]data_bank;
wire [10:0]bank;
wire [2:0]state;
wire [4:0]data_base;
wire [5:0]data_base_or90;
wire reset_autostart;
reg [1:0]ctr_init;
wire clock_spi;
wire [7:0]data_spi;
wire [7:0]data_offset;

reg flag_autostart;
wire [1:0]ss;
wire led_state;
wire flag_reset;
wire flag_offset;
wire flag_id;
wire flag_pgm;
wire flag_hidden;
wire flag_hidden_or90;
wire hard_reset;

wire ce_ffxx;
wire [3:0]_cfg;

assign _cfg =              !cfg;

assign hard_reset =        (!_reset & !switch[1]) | (flag_reset ? !_reset : reset_long);
assign reset_autostart =   hard_reset | (!ctr_init[1]);

assign led =               (hard_reset ? 1 : _reset & led_state); // show hard_reset and state of led, assuming reset is not held down
assign _ss =               !(ss[1:0] == 'b01);
assign _ss2 =              !(ss[1:0] == 'b10);

assign flag_hidden =       data_base[4];
assign flag_hidden_or90 =  data_base_or90[5];

//assign clock_spi = 		  q ^ e;  // doubled clock
assign clock_spi = 			e;

assign _cart = 				(flag_autostart & !q ? 0 : 'bz);

assign ce_ffxx =           (address[15:8] == 8'hff);
assign ce_reg_base =			ce_ffxx & (address[7:0] == 8'h80);  //ff80
assign we_reg_base =			!r_w & ce_reg_base;  //ff80

//assign ce_or90 =           (ce_ffxx & (address[7:1]== 'b0111101)); //ff7a and ff7b
assign ce_or90 =           (
                            !flag_hidden_or90                  // we're not hidden
                            & _slenb                           // no one else is trying to sue the bus
                            & 
                            (
                             (
                              !_scs                            // our address in in lower half and we're in the selected slot.
                              & !data_base_or90[4]
                             )
                             | 
                             (
                              data_base_or90[4]                // or we're in the upper slot
                              & ce_ffxx                        // and we're in $ffxx
                              & 
                              (
                               address[7:5] == 3'b011          // they're asking for $ff6x or $ff7x
                              )
                             )
                            )
                            & 
                            (
                             address[4:1] == data_base_or90[3:0] // and top 3 bits of address are a match
                            )
                           ); // default to ff7a and ff7b
assign we_or90 =           ce_or90 & !r_w & e;
assign _channel[0] =       !(we_or90 & !address[0]);
assign _channel[1] =       !(we_or90 & address[0]);

assign baddress = 			{bank,address[11:0]};

assign ce_reg =            (
                            !flag_hidden                       // CocoFLASH is not hidden
                            & _slenb                           // no one is using the bus
                            & 
                            (                                
                             (
                              !_scs                            // we're in the lower half and we're in the selected slot
                              & !data_base[3]
                             ) 
                             | 
                             (
                              data_base[3]                     // or we're in the upper half
                              & ce_ffxx                        // and $ffxx is active
                              &
                              (
                               address[7:5] == 3'b011          // and they're asking for 6x or 7x
                              )
                             )
                            ) 
                            &
                            (
                             address[4:2] == data_base[2:0]    // and top 2 bits of address are a match
                            )
                           ); // b11111111 01 xxxx 00 - ff40-ff7c
assign we_reg =            !r_w & ce_reg;
assign we_reg_cmd = 			(we_reg & (address[1:0] == 0));
assign we_reg_bank_lo =    (we_reg & (address[1:0] == 1));
assign we_reg_bank_hi =    (we_reg & (address[1:0] == 2));
assign we_reg_spi = 	      (we_reg & (address[1:0] == 3));

assign we_reg_offset = 	   (!r_w & !ce_reg & !ce_or90 & !_scs & flag_offset);

assign data = 					(e & r_w & (!_cts | ce_reg | ce_or90) ? data_mux : 8'bz);
assign _oe = 					_cts;
assign _we = 					!(e & !r_w & address[15] & address[14] & !address[13] & flag_pgm); // you can write to c000-dfff  
assign _slenb =            (!_we |  we_reg_base ? 0 : 'bz);
assign bdata = 				(_we ? 8'bz : data);
assign _freset =           _reset;

assign bank[10:0] = 			data_bank[10:0] + {8'b0, address[14:12]} + {'b0, data_offset[7:0], 2'b0};


register #(.WIDTH(5),.RESET(5'b01001))	   reg_base(
                                                   e, 
                                                   hard_reset, 
                                                   we_reg_base & (state == 4) & (data[1:0]==cfg[1:0]), 
                                                   {data[7],data[5:2]}, data_base
                                                  ); //ff64 default.
register #(.WIDTH(6),.RESET(6'b011101))	reg_base_or90( // 011011 = bits 7,5-1 of address = 0(1)11 = 7 and 101X = A/B
                                                     e, 
                                                     hard_reset, 
                                                     we_reg_base & (state == 6) & (data[1:0]==_cfg[1:0]), 
                                                     {data[7],data[5:1]}, 
                                                     data_base_or90
                                                    ); //ff7a default.

/*
  Command Register:
  0: 0 - LED off, 1 - LED on                          / switch0 on read
  1: 0 - CART High-Z, 1 - CART = Q                    / switch1 on read
  2: 1 - select SPI channel 0                         / X
  3: 1 - select SPI channel 1                         / X
  4: 1 - hard reset = reset                           / X
  5: 1 = offset active                                / X
  6: 0 = select MFR/VER data, 1 = select bank data    / X
  7: 0 - FLASH write off, 1 - FLASH Write on          / X
  
*/
register #(.WIDTH(6)) 		reg_cmd(
                                   e, 
                                   !_reset, 
                                   we_reg_cmd, 
                                   {data[7], data[6], data[4], data[3], data[2], data[0]}, 
                                   {flag_pgm, flag_id, flag_reset, ss[1], ss[0], led_state}
                                  );
register #(.WIDTH(1)) 		reg_cmd_offset(
                                          e, 
                                          hard_reset, 
                                          we_reg_cmd, 
                                          data[5], 
                                          flag_offset
                                         );

register 						reg_bank_lo(e, hard_reset, we_reg_bank_lo, data[7:0], data_bank[7:0]);
register #(.WIDTH(3))		reg_bank_hi(e, hard_reset, we_reg_bank_hi, data[2:0], data_bank[10:8]);
spi             				spi1(clock_spi, hard_reset, e & we_reg_spi, data, data_spi, sck, miso, mosi );
register							reg_offset(e, !_reset, we_reg_offset, data, data_offset);

mux4_1							mux_native(
                                      address[1:0], 
                                      {'b0, 'b0, flag_offset, 'b0 , 'b0, 'b0, !switch[1], !switch[0]}, 
                                      data_bank_id, 
                                      data_bank_ver, 
                                      data_spi, 
                                      data_reg
                                     );
mux2_1							mux_mfr(
                                   flag_id, 
                                   data_bank[7:0], 
                                   {FAM_RI,ID_CF}, 
                                   data_bank_id
                                  );
mux2_1							mux_ver(
                                   flag_id, 
                                   {5'b0,data_bank[10:8]}, 
                                   {VER_CF,_cfg[3:0]}, 
                                   data_bank_ver
                                  );
mux2_1							mux_cc90(
                                    address[0], 
                                    {FAM_RS,ID_OR90}, 
                                    {VER_OR90,_cfg[3:0]}, 
                                    data_reg_or90
                                   );
mux2_1							mux_reg(
                                   ce_reg, 
                                   data_reg_or90, 
                                   data_reg, 
                                   data_regc
                                  );


mux2_1							mux_1(
                                 _cts, 
                                 bdata, 
                                 data_regc, 
                                 data_mux
                                );

fsm								fsm1(
                                we_reg_base & e, 
                                !_reset | (ce_reg_base & e & r_w), 
                                data, 
                                state, 
                                {FAM_RI,ID_CF},
                                {FAM_RS,ID_OR90}
                               );

// this is a small counter to create an event for the initial setting of flag_autostart.  When the value reaches 2, flag_autostart will no longer
// respond to switch0
always @ (posedge e)
  begin
    if(!ctr_init[1])
		ctr_init <= ctr_init + 1;
  end

// on the falling edge of e, if reset_autostart is high, set autostart to switch0, else if reg_cmd is written, pull from data[1]
initial flag_autostart = 1;
always @ (negedge e)  
  begin
  if(reset_autostart)
		flag_autostart <= switch[0];
  else if(we_reg_cmd)
	   flag_autostart <= data[1];
  end


endmodule

module fsm(
           input clock, 
           input reset, 
           input [7:0]data, 
           output reg [2:0]state,
           input [7:0]magic1,
           input [7:0]magic2
          );

always @(negedge clock, posedge reset)
begin
  if(reset)
		state <= 0;
  else 
		case(state)
         0:
				if(data == 8'h55)
					state <= 1;
			1:
				if(data == 8'haa)
					state <= 2;
				else
					state <= 0;
			2:
				if(data == magic1)
					state <= 3;
            else if(data == magic2)
               state <= 5;
				else
					state <= 0;
			3:
				if(data == 8'h01)
					state <= 4;
				else
					state <= 0;
			5:
				if(data == 8'h01)
					state <= 6;
				else
					state <= 0;
			default:
               state <= 0;
		endcase
end
endmodule
