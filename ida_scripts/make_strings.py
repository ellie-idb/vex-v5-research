##############################################################################################
# Copyright 2017 The Johns Hopkins University Applied Physics Laboratory LLC
# All rights reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this 
# software and associated documentation files (the "Software"), to deal in the Software 
# without restriction, including without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
# OR OTHER DEALINGS IN THE SOFTWARE.
#
# 2020-08-07 - modified to work on IDA 7.x - Alexander Pick (alx@pwn.su)
#

##############################################################################################
# make_strings.py
# Searches the user entered address range for a series of ASCII bytes to define as strings.
# If the continuous series of ASCII bytes has a length greater or equal to minimum_length and
# ends with a character in string_end, the scripts undefines the bytes in the series
# and attempts to define it as a string.
#
# Input: 	start_addr: 	Start address for range to search for strings
#			end_addr:		End address for range to search for strings
#
##############################################################################################

################### USER DEFINED VALUES ###################
min_length = 5           			# Minimum number of characters needed to define a string       
string_end = [0x00]		# Possible "ending characters" for strings. A string will not be 
                                    # defined if it does not end with one of these characters
###########################################################

start_addr = ida_kernwin.ask_addr(ida_ida.inf_get_min_ea(), "Please enter the starting address for the data to be analyzed.")
end_addr = ida_kernwin.ask_addr(ida_ida.inf_get_max_ea(), "Please enter the ending address for the data to be analyzed.")

if ((start_addr is not None and end_addr is not None) and (start_addr != BADADDR and end_addr != BADADDR) and start_addr < end_addr):
	string_start = start_addr
	print("[make_strings.py] STARTING. Attempting to make strings with a minimum length of %d on data in range 0x%x to 0x%x" % (min_length, start_addr, end_addr))
	num_strings = 0
	while string_start < end_addr:
		num_chars = 0
		curr_addr = string_start
		while curr_addr < end_addr:
			byte = idc.get_wide_byte(curr_addr)
			if ((byte < 0x7F and byte > 0x1F) or byte in (0x9, 0xD, 0xA)):		# Determine if a byte is a "character" based on this ASCII range
				num_chars += 1
				curr_addr += 1			
			else:
				if ((byte in string_end) and (num_chars >= min_length)):
					ida_bytes.del_items(string_start, curr_addr - string_start, DELIT_SIMPLE)
					if (ida_bytes.create_strlit(string_start, 0, ida_nalt.STRTYPE_TERMCHR) == 1): #get_inf_attr(INF_STRTYPE)
						print("[make_strings.py] String created at 0x%x to 0x%x" % (string_start, curr_addr))
						num_strings += 1
						string_start = curr_addr
						break
					else:
						#print "[make_strings.py] String create FAILED at 0x%x to 0x%x" % (string_start, curr_addr)
						break
				else:		
					# String does not end with one of the defined "ending characters", does not meet the minimum string length, or is not an ASCII character
					break
		string_start += 1
	print("[make_strings.py] FINISHED. Created %d strings in range 0x%x to 0x%x" % (num_strings, start_addr, end_addr))
else:
	print("[make_strings.py] QUITTING. Entered address values not valid.")