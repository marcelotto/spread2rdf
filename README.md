# Spread2RDF

Spread2RDF is a converter for complex spreadsheets to RDF and a Ruby-internal
[DSL](http://en.wikipedia.org/wiki/Domain-specific_language)
for specifying the mapping rules for this conversion.

## Features

* Supports Excel/Excelx, Google spreadsheets, OpenOffice, LibreOffice and CSV
  spreadsheets as input, thanks to [Roo](https://github.com/Empact/roo).
  (Currently, it's tested for Excel only.
  If you have a problem with another spreadsheet type,
  [raise an issue](https://github.com/marcelotto/spread2rdf/issues).)
* Supports many RDF serialization formats for the output, thanks to
  [RDF.rb](https://github.com/ruby-rdf/rdf).
* Mapping definitions are compilable to executables, which can be run without
  Ruby installed.

## Installation

Install [Ruby](http://www.ruby-lang.org/) and execute the following command
in a terminal:

    $ gem install spread2rdf

## Author

* Marcel Otto
