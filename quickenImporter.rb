#!/usr/bin/env ruby
#
# QUICKENIMPORTER
#
# Purpose:
# Read all records of an input file containing transaction data from DWS
# convert and store them in another file in Quicken qif format
# This file can subsequently used to import the transactions into Quicken
#
# Call quickenImporter [-v] [-f [inputfilename]]
#
# Author: Martin Reese
#
# Version History
# 23.05.2015: V0.01 initial version, basic ruby setup, reading file
# 15.07.2015: V0.02 basic output creation finished 
# 20.07.2015: V0.03 DWS transaction csv input format implemented
#

# Constants
USAGE = <<ENDUSAGE
Usage:
   quickenImporter [-v] [-h] [-i] [-f [inputfilename]]
ENDUSAGE

HELP = <<ENDHELP
   -h, --help       Show this help.
   -v, --version    Show the version number.
   -i, --inspect    Inspect processing details
   -f, --file       Specify the input file name.
ENDHELP

VERSION = "0.03"

# FILE FORMATS
IN_NO_OF_ATTRIBUTES = 9
IN_DELIMITER = ";"
OUT_DELIMITER = "\r\n"
in_structure  = [:preistag, :umsatzart, :fondsname, :investmentfonds, :zusatzinformation, :anteile, :preis, :betrag, :waehrung]
# out_structure = {:start=>nil, :val1=>nil, :val4=>nil, :val3=>nil, :val2=>nil, :end=>nil}  not used

# Infile Transaction types:
# "Beitrag" = Kauf
# "Umschichtung" = Verkauf
# "Depotentgeld" = Gebühren
# "Gutschrift Zulage" = Kauf 
# "Gutschrift Kinderzulage" = Kauf 


# Read command line params
nextarg = nil
filename = nil
inspect = false
ARGV.each do |arg|
  case arg
    when "-f","--file" then
	  nextarg = :file
    when "-v","--version" then
      print "\n" + $0 + " version " + VERSION + "\n"
    when "-i","--inspect" then
	  inspect = true
	when "-h","--help" then
	  puts HELP
    else
      if nextarg == :file
	    filename = arg
	  else
        puts USAGE
		break
      end		
  end
end
if filename == nil
  puts USAGE
  Kernel.exit
end
  
# Read input file
if filename
  file = File.new(filename, "r")
  lines = file.readlines
  if inspect
    puts "Datei eingelesen:\n"
    lines.each do |line| 
      puts line
	end
  end
end

# Process records
if inspect
  puts "Importiere Werte ..."
end
in_records = Array.new							# array of hashes
lines.each do |line|
  line = line.chomp("\n")						# remove EOL (any better idea to do it smarter?
  if line.length != 0
    line_array = line.split(IN_DELIMITER)         # [wert1, wert2, wert3, wert4]
    if line_array.length != IN_NO_OF_ATTRIBUTES
	  if inspect
	    puts "Falsche Anzahl an Attributen in Eingangsdatei: #{IN_NO_OF_ATTRIBUTES} erwartet, aber #{line_array.length} gefunden\n"
	    puts line_array.inspect
	  end
	  Kernel.exit
    end
    line_array2 = in_structure.zip(line_array)    # [[:val1=>wert1], [:val2=>wert2], [:val3=>wert3], [:val4=>wert4]]
    line_array3 = line_array2.flatten             # [:val1, wert1, :val2, wert2, val3, wert3, :val4, wert4]
    line_hash = Hash[*line_array3]                # {:val1=>wert1, :val2=>wert2, :val3=>wert3, :val4=>wert4}
    in_records << line_hash
  end
end
if inspect
  in_records.each do |record|
    puts record.inspect
  end
  puts "\nWerte importiert: #{in_records.length} Datensätze eingelesen"
end

# Create output records
out_records = Array.new							# array of hashes
in_records = in_records.drop(1)					# remove header line 
in_records.each do |record|
  out_record = Hash.new
#  out_record = out_structure					# does not work
  out_record[:start] = "START"
  out_record[:val1] = record[:fondsname]
  out_record[:val2] = record[:preis]
  out_record[:val3] = record[:anteile]
  out_record[:val4] = record[:umsatzart]
  out_record[:end] = "END"
  out_records << out_record
end
if inspect
  puts "\nOutput records:\n"
  puts out_records.inspect
end

# Write output file
out_records.each do |record|
  record.each do |key, value|
    print key
	print " "
    print value
	print OUT_DELIMITER
  end
  
  
  
end

