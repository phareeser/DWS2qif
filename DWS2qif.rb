#!/usr/bin/env ruby
#
# DWS2qif
#
# Purpose:
# Read all records of an input file containing transaction data from DWS
# convert and store them in another file in Finanzmanager qif format
# This file can subsequently used to import the transactions into Finanzmanager
#
# Call DWS2qif [-v] [-f [inputfilename]]
#
# Author: Martin Reese
#
# Version History
# 23.05.2015: V0.01 initial version, basic ruby setup, reading file
# 15.07.2015: V0.02 basic output creation finished
# 20.07.2015: V0.03 DWS transaction csv input format implemented
# 21.07.2015: V0.04 QIF format implemented; not yet checked for completeness
# 23.07.2015: V0.05 writing into output file, format conversions implemented; datefrom and dateto implemented
# 27.07.2015: V0.90 minor corrections, unit tested successfully
# 11.09.2015: V0.91 fixed bug in type 'Umschichtung' -> can be Kauf or Verkauf based on +- sign
# 24.01.2016: V0.92 forced encoding to iso-8859-1; introduced new transaction type 'Rueckforderung Zulage'
# 10.02.2018: V0.93 added "Wiederanlage Ertragssteuer"
# 24.01.2019: V0.94 added "Verwaltungskosten d. Vertrages" and "Verkauf wegen Depotentgelt"
#
#
# Mapping infile to outfile transaction types:
# "Beitrag" -> Kauf
# "Umschichtung" -> Verkauf or Kauf, based on +- sign
# "Depotentgelt" -> Verkauf
# "Verwaltungskosten d. Vertrages" -> Verkauf
# "Verkauf wegen Depotentgelt" -> Verkauf
# "Gutschrift Zulage" -> Kauf
# "Gutschrift Kinderzulage" -> Kauf
# "Kauf VL zum Ausgabepreis" -> Kauf
# "Wiederanlage der Ausschuettung" -> Retshrs
# "Wiederanlage von Ertragsteuer" -> Retshrs
# "Rueckforderung Zulage" -> Verkauf

require 'date'

# Constants
USAGE = <<ENDUSAGE
Usage:
   quickenImporter [-v] [-h] [-i] [-f [inputfilename]] [-df [from_date]] [-dt [to_date]]
ENDUSAGE

HELP = <<ENDHELP
   -h, --help       Show this help.
   -v, --version    Show the version number.
   -i, --inspect    Inspect processing details.
   -f, --file       Specify the input file name.
   -df,--datefrom	Convert transactions after or same as given date, ignore the rest
   -dt,--dateto		Convert transactions before or same as given date, ignore the rest
ENDHELP

VERSION = "0.94"

# FILE FORMATS
IN_NO_OF_ATTRIBUTES = 9
IN_DELIMITER = ";"
OUT_DELIMITER = "\n"
in_structure  = [:preistag, :umsatzart, :fondsname, :investmentfonds, :zusatzinformation, :anteile, :preis, :betrag, :waehrung]
# out_structure = {:start=>nil, :val1=>nil, :val4=>nil, :val3=>nil, :val2=>nil, :end=>nil}  not used

# Read command line params
nextarg = nil
filename = nil
inspect = false
datefrom = nil
dateto = nil
ARGV.each do |arg|
  case arg
    when "-f","--file" then
	  nextarg = :file
    when "-df","--datefrom" then
	  nextarg = :datefrom
    when "-dt","--dateto" then
	  nextarg = :dateto
    when "-v","--version" then
      print "\n" + $0 + " version " + VERSION + "\n"
    when "-i","--inspect" then
	  inspect = true
	when "-h","--help" then
	  puts HELP
    else
      if nextarg == :file
	    filename = arg
      elsif nextarg == :datefrom
	    datefrom = Date.parse(arg)
      elsif nextarg == :dateto
	    dateto = Date.parse(arg)
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
  file.close
end

# Import records
in_record_counter = 0
if inspect
  puts "Importiere Werte ..."
end
in_records = Array.new							# array of hashes
lines.each do |line|
  line = line.chomp("\n")						# remove EOL (any better idea to do it smarter?
  if line.length != 0
    in_record_counter = in_record_counter + 1
    line_array = line.force_encoding("iso-8859-1").split(IN_DELIMITER)         # [wert1, wert2, wert3, wert4]
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
# Map input to output records
out_records = Array.new													# array of hashes
in_records = in_records.drop(1)											# remove header line
in_record_counter = in_record_counter - 1
in_records.each do |record|
#  out_record = out_structure											# does not work
  date = Date.strptime(record[:preistag].to_s, "%d.%m.%Y")
  if ((datefrom.nil? or (date >= datefrom)) and (dateto.nil? or (date <= dateto)))
    date = date.strftime("%m.%d.%Y")										# qif requires format "month"."day"."year"
    out_record = Hash.new
    out_record[:D] = date													# transaction date
    out_record[:V] = date													# valuta date
    case record[:umsatzart]												# transaction type
      when "Beitrag"
	      out_record[:N] = "Kauf"
      when "Umschichtung"
        if record[:betrag].to_s.gsub(',', '.').to_f > 0
		      out_record[:N] = "Kauf"
		    else
		      out_record[:N] = "Verkauf"
        end
      when "Depotentgelt"
	      out_record[:N] = "Verkauf"
      when "Verwaltungskosten d. Vertrages"
        out_record[:N] = "Verkauf"
      when "Verkauf wegen Depotentgelt"
        out_record[:N] = "Verkauf"
      when "Rueckforderung Zulage"
	      out_record[:N] = "Verkauf"
  	  when "Gutschrift Zulage"
  	    out_record[:N] = "Kauf"
  	  when "Gutschrift Kinderzulage"
  	    out_record[:N] = "Kauf"
  	  when "Kauf VL zum Ausgabepreis"
  	    out_record[:N] = "Kauf"
  	  when "Wiederanlage der Ausschuettung"
  	    out_record[:N] = "Retshrs"
  	  when "Wiederanlage von Ertragsteuer"
  	    out_record[:N] = "Retshrs"
  	  else
  	    puts "Unknown Transaction: " + record[:umsatzart]
  	    exit
    end

	record[:betrag]  = record[:betrag].to_s.gsub(',', '.').to_f.abs 		# always use positive values (transaction type indicates increase or decrease of shares)
    record[:anteile] = record[:anteile].to_s.gsub(',', '.').to_f.abs
    record[:preis]   = record[:preis].to_s.gsub(',', '.').to_f.abs

	if ((record[:umsatzart] == "Depotentgelt") || (record[:umsatzart] == "Verwaltungskosten d. Vertrages") || (record[:umsatzart] == "Verkauf wegen Depotentgelt"))
	  out_record[:E] = "Depotkosten:Depotgebühren"
	  out_record[:O] = "0.00|0.00|0.00|0.00|0.00|0.00|0.00|" + record[:betrag].to_s + "|0.00|0.00|0.00|0.00"
	else
	  out_record[:U] = record[:betrag]									# transaction amount
	end
    out_record[:F] = record[:waehrung]									# currency
    out_record[:I] = record[:preis]										# price of a share
    out_record[:Q] = record[:anteile]									# number of shares
    out_record[:L] = out_record[:N] == "Verkauf" ? "Kursgewinne:Realisierte Gewinne" : out_record[:N] == "Retshrs" ? "Kapitalerträge:sonstige Einnahme" : ""
    fondsname = record[:fondsname].split('/')							# fonds name
    if (fondsname[1])
      out_record[:Y] = fondsname[1].strip
	    out_record[:L] << "|[" + fondsname[0].strip + "]"					# category or transfer and (optionally) Class
	  else
      out_record[:Y] = fondsname[0].strip
    end

    out_records << out_record
  end
end
if inspect
  puts "\nOutput records:\n"
  puts out_records.inspect
end

# Write output file
filename = filename + ".qif"
file = File.new(filename, "w")
out_record_counter = 0
if inspect
  puts "!Type:Invst"
end
printf(file, "!Type:Invst\n")
out_records.each do |record|
  out_record_counter = out_record_counter + 1
  record.each do |key, value|
  if inspect
      print key
      print value
	  print OUT_DELIMITER
  end
	printf(file, "%s%s%s", key, value, OUT_DELIMITER)
  end
  if inspect
    puts "^"
  end
  printf(file, "^\n")
end
file.close

puts "\r\nDONE\r\n"
puts "Read " + in_record_counter.to_s + " records\r\n"
puts "Wrote " + out_record_counter.to_s + " records\r\n"
