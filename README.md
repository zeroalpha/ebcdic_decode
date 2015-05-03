# ebcdic_decode
A Ruby tool to convert IBM EBCDIC Datasets to Unicode Files

# Features
* Convert z/OS Sequential-Datasets with Fixed or Variable Blocked Record Format to Unicode Files
* Create new maps from Wikipedia Articles with Translation tables
* Download Variable Blocked Datasets via FTP including the RDW (Record Descriptor Word)

# To do
* Package as Gem
* Refactor MapGenerator
--* Find feasabile Storage format
--* Cut the wikipedia parsing code out
--* Add more parsers
* Add tests
* Refactor get_zos_dataset into a class and move it to lib
* Package as Gem

# Usage
-f/--file or -I/--install are required!
-c/--ccsid specifies the Codepage

## Convert
```
$ bundle exec ruby ebcdic_decode.rb -f <INPUT_DATASET> -c 1047 -recfm FB -lrecl 80 -o <OUTPUT_FILE>
```
This would be a general use-case. Since it is so common, if not specified, recfm will default to FB and lrecl to 80

## Create new character map
```
$ bundle exec ruby ebdcic_decode.rb -I http://en.wikipedia.org/wiki/EBCDIC_500 -e 1148
```
Here the -e option specifies the CCSID of the Euro(€) update of the character set.
If it is set, another map will be created alongside the one specified with the url. 
The only difference will be the name and byte 0x9F will be set to "\u20AC" (€ symbol)