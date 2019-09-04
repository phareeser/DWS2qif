DWS2qif

Purpose:
Read all records of an input file containing transaction data from DWS
convert and store them in another file in Finanzmanager qif format
This file can subsequently used to import the transactions into Fianazmanager

Call DWS2qif [-v] [-f [inputfilename]]

Author: Martin Reese

Version History
23.05.2015: V0.01 initial version, basic ruby setup, reading file
15.07.2015: V0.02 basic output creation finished
20.07.2015: V0.03 DWS transaction csv input format implemented
21.07.2015: V0.04 QIF format implemented; not yet checked for completeness
23.07.2015: V0.05 writing into output file, format conversions implemented; datefrom and dateto implemented
27.07.2015: V0.90 minor corrections, unit tested successfully
11.09.2015: V0.91 fixed bug in type 'Umschichtung' -> can be Kauf or Verkauf based on +- sign
24.01.2016: V0.92 forced encoding to iso-8859-1; introduced new transaction type 'Rueckforderung Zulage'
10.02.2018: V0.93 added "Wiederanlage Ertragssteuer"
24.01.2019: V0.94 added "Verwaltungskosten d. Vertrages" and "Verkauf wegen Depotentgelt"


Mapping infile to outfile transaction types:
"Beitrag" -> Kauf
"Umschichtung" -> Verkauf or Kauf, based on +- sign
"Depotentgelt" -> Verkauf
"Verwaltungskosten d. Vertrages" -> Verkauf
"Verkauf wegen Depotentgelt" -> Verkauf
"Gutschrift Zulage" -> Kauf
"Gutschrift Kinderzulage" -> Kauf
"Kauf VL zum Ausgabepreis" -> Kauf
"Wiederanlage der Ausschuettung" -> Retshrs
"Wiederanlage von Ertragsteuer" -> Retshrs
"Rueckforderung Zulage" -> Verkauf
