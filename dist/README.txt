The disk image prgflash.dsk contains the following utilities...
PRGFLASH.BAS	Utility to program the CoCo Flash with new ROMs/games.
PRGFLASH.BIN	Used by PRGFLASH.BAS.
SPLIT.BAS	Utility to split large ROMs into 16k segments.
BINLOAD.BIN	Stick this in front of a disk binary that is smaller than 16k to
		make it into a ROM.
BINLOAD2.BIN	Same as BINLOAD.BIN, but for larger disk binaries.
BASLOAD.BIN	This routine is used to make a BASIC program ROMable.
MENU.BAS	This is the customizable menu for the CoCo Flash, RUN 60000 to
		create a ROMable bin file from this BASIC program.
BASROM.BIN	This is MENU.BAS converted to a .bin file that can be loaded
		into a ROM bank. It is created by RUN 60000 with MENU.BAS
		loaded.
CONV2BIN.BAS	This program will convert a raw ROM image like a .ccc file or a
		16k segment from SPLIT.BAS to a .bin that PRGFLASH.BAS can
		be programed into the CoCo Flash by PRGFLASH.BAS.
CONV2BIN.BIN	Machine language routines used by CONV2BIN.BAS.
3AUTHORS.BAS	Just a program to "hard" reset a CoCo 3.
STRTSLOT.BAS	A small program to startup a select slot in a MPI.

The disk image hdbdosl.dsk contains the following utilities...
LOADFIRM.BAS	Erases and reprograms a CoCo Flash back to it's original
		contents.
HDBLNCH.BIN	Used to selectively launch the correct version of HDBDOS for
		either a CoCo 1/2 or a CoCo 3.
DW3CC1.BIN	HDBDOS for a CoCo 1 or 2 using DriveWire.
DW3CC3.BIN	HDBDOS for a CoCo 3 using DriveWire.
PRGFLASH.BAS	Used to write .bin ROM files into the CoCo Flash.
PRGFLASH.BIN	Used by PRGFLASH.BAS and LOADFIRM.BAS.
DOODLE.BIN	Doodle Bug ROM.
BUZZARD0.BIN	Part 1 of 2 of th Buzzard Bait ROM.
BUZZARD1.BIN	Part 2 of 2 of th Buzzard Bait ROM.
TEMPLE.BIN	Temple of ROM ROM.
ORC90.BIN	Orchestra 90 ROM.
MENU.BAS	This is the customizable menu for the CoCo Flash, RUN 60000 to
		create a ROMable bin file from this BASIC program.
BASLOAD.BIN	This routine is used to make a BASIC program ROMable.
BASROM.BIN	This is MENU.BAS converted to a .bin file that can be loaded
		into a ROM bank. It is created by RUN 60000 with MENU.BAS
		loaded.
