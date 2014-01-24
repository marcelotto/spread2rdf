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

### Command-line interface

For a description of all available parameters, type the following in a terminal:

    $ spread2rdf --help

## How it works

You write a mapping file for an Excel file or a bunch of Excel files with the
same structure, whose data should be converted to RDF.
You apply the mapping file to an Excel file using the ```spread2rdf```
command-line interface or a compiled version of the mapping file.

### Example mapping

```ruby
require 'spread2rdf'

module Spread2RDF
  Schema.definition 'ProSysMod-Data' do

    namespaces(
      PSM:    'http://example.com/ProSysMod/ontology#',
      QUDT:   'http://qudt.org/schema/qudt#'
    )

    worksheet 'RDF-Export', name: :Settings do
      NS[:Base]                = cell(:B7)
      NS[:PSM_MaterialElement] = cell(:B9)
    end

    worksheet 'MaterialelementeKlassen',
              name:    :MaterialElementClasses,
              start:   :B5,
              subject: { uri: { namespace: PSM_MaterialElement },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.MaterialElement
              } do
      column :name, predicate: RDFS.label
      column :uri

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object:    { from: :MaterialElementClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.materialParameter,
                                statement: :restriction do
        column :name,        predicate: PSM.parameterName
        column :description, predicate: PSM.parameterDescription

        column :min,   predicate: PSM.parameterMinQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :exact, predicate: PSM.parameterQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :max,   predicate: PSM.parameterMaxQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :unit, object: lambda do |value|
          statements(
               [ object, QUDT.numericValue, value.to_i ],
               [ object, QUDT.unit, object_of_column(:unit) ] )
        end
      end
    end

    worksheet 'Materialelemente',
              name:   :MaterialElements,
              start:  :B5,
              subject: { uri: { namespace: PSM_MaterialElement },
                         type: PSM.MaterialElement
              } do
      column :name, predicate: RDFS.label
      column :uri

      column :type,             predicate: RDF.type,
                                object:    { from: :MaterialElementClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                   predicate: PSM.materialParameter,
                   &parameter_block

      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.materialParameter do
        column :name,        predicate: PSM.parameterName
        column :description, predicate: PSM.parameterDescription

        column :min,   predicate: PSM.parameterMinQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :exact, predicate: PSM.parameterQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :max,   predicate: PSM.parameterMaxQuantity,
                       object:    { uri: :bnode, type: QUDT.QuantityValue },
                       &quantity_mapping
        column :unit, object: lambda do |value|
          statements(
               [ object, QUDT.numericValue, value.to_i ],
               [ object, QUDT.unit, object_of_column(:unit) ] )
        end
      end
    end
  end
end
```

A complete example mapping file using most of the features can be found
[in the examples directory](examples/ProSysMod.s2r.rb).

### Mapping definition file

A mapping file is a Ruby file containing a definition like this:

```ruby
require 'spread2rdf'

module Spread2RDF
  Schema.definition 'Name-of-the-mapping-schema' do

  end
end
```

The name is purely descriptive and currently not used for anything else.
Into the definition block goes the description of the schema of a spreadsheet
and the conversion rules for mapping its cells to RDF.

### URIs and namespaces

URIs can be written in the form ```Namespace.suffix```, where the namespace is
written in uppercase.
The most common namespaces like ```RDF, RDFS, OWL, SKOS, XSD, DC, FOAF``` (all
predefined [RDF.rb vocabularies](http://rubydoc.info/github/ruby-rdf/rdf/master/RDF/Vocabulary))
are available without declaration.
Additional namespaces can be defined statically using the method ```namespace```
inside the schema definition block, as in the example above:
```ruby
module Spread2RDF
  Schema.definition 'Name-of-the-mapping-schema' do
    namespaces(
      EX:   'http://www.example.com/',
      QUDT: 'http://qudt.org/schema/qudt#'
    )
  end
end

```
If a namespace should be declared dynamically, for example from to the content
of a cell of a worksheet, an element can be added to the hash of namespaces
```NS```, where the namespace name is given as a Ruby symbol:
```ruby
worksheet 'Settings' do
  NS[:EX] = cell(:B7)
end
```

### Worksheet schema definitions
The schema definition block should contain a worksheet definition for
every worksheet with content to be processed.
It consists of
- the keyword ```worksheet```,
- followed by a string with the name of the worksheet used in the spreadsheet,
- a list of named parameters (described below),
- and a block with column or column block definitions or arbitrary cell
  processing like in the ```Settings``` worksheet above.
The order of the worksheet definitions is insignificant.

###### ```name``` parameter
If you want to refer to a worksheet (e.g. in the ```subject``` parameter) under
a different name than the one used in the spreadsheet (e.g. because it contains
whitespaces), you can define it with this parameter.

###### ```start``` parameter
The upper-left cell of the data to be converted as a Ruby symbol.
Assuming the first row is a header (which is irrelevant for the conversion), the
default value for this parameter is ```:A2```.

###### ```subject``` parameter
This parameter specifies the construction of a subject resource for a row and
expects a hash with further sub-parameters as its value:
- ```uri```: Defines the rules to construct an URI for the subject, possible values:
  - ```:bnode```: Construct a blank node for every subject.
  - Another hash if a full URI should be constructed with the following possible
    parameters:
    - ```column```: The name of a column as a Ruby symbol, which contains the
      base value for the construction of an URI for a subject.
      In the following I will call this the subject column.
      The default value for this is ```:uri```.
    - ```namespace```: The namespace used to construct a URI for a subject by
      concatenation with the corresponding value of the subject column.
      If this is not specified, it is assumed that the subject column contains
      absolute URIs.
- ```type```: The URI of a RDFS class every subject should be an element of,
  i.e. for every subject a ```rdf:type``` statement is produced with this URI as
  its object.
- ```sub_class_of```: The URI of a RDFS class every subject should be a
  ```rdfs:subClassOf``` of,
  i.e. for every subject a ```rdfs:subClassOf``` statement is produced with
  this URI as its object.
- ```column```: shortcut for the ```column``` sub-parameter of the ```uri``` parameter

Note, that the rows for a subject might span multiple rows of a worksheet, for
example when another column contains multiple rows with values for the same
subject.
The range of rows for a subject is defined by the subject column according to
the following criteria:
- The first row for a subject is the row with a non-empty value in the subject
  column (by default the column ```:uri```).
- The last row for a subject is the last row with an empty value in the subject
  column or the last row of the worksheet.

### Column schema definitions
A column definition consists of
- the keyword ```column```,
- followed by a Ruby symbol with the arbitrary name of the column,
- an optional list of named parameters (described below),
- and an optional block with custom logic (described below).
The order of the column definitions is significant and must correspond to the
order of columns of the worksheet.
Columns which should be ignored, simply leave the optional parameter and block empty.
Note, that the first column is defined by the ```start``` parameter of the
worksheet.

###### ```predicate``` parameter
The URI of a RDF property which should be used for construction of triples for
values this column.
Leaving this parameter unspecified has the same effect as setting ```statement```
to ```:none```.

###### ```object``` parameter
This parameter specifies the construction of an object resource or value for a
row and expects a hash with further sub-parameters as its value:
- ```language```:
  A string or Ruby symbol with a language to be used to tag the string value of
  the generated triple.
- ```uri```:
  Specifies the rule for the generation of a resource for the object
  of a triple. Currently, the following values are possible:
  - ```:bnode```:
    Generate a blank node, which makes mostly sense in conjunction
    with the specification of a Ruby block for custom logic (see below), where
    additional statement about this object are generated.
  - A Hash with a ```namespace``` key and a namespace as the value, which used
    to construct an URI by concatenation with the corresponding cell value of
    the column.
- ```type```:
  The URI of a RDFS class every object resource should be an element of, i.e.
  for every object a ```rdf:type``` statement is produced with this URI as its
  object.
- ```from```:
  Allows the specification of other data sources from which a resource is
  referenced with a value of the column.
  The graph of this data source is therefore queried for a resource with the
  value of the column as its ```rdfs:label``` (currently this property is hard
  coded, but could be made configurable).
  The value of this parameter can be a Hash with one or a combination of the
  following keys or a single Ruby symbol as a shortcut ```worksheet``` or a
  single string or hash as a shortcut for ```data_source```.
  - ```worksheet```: The name of a worksheet, whose generated output graph
    should be queried.
  - ```data_source```: A single filename or an array of filenames of RDF files,
    which should be queried.
    In case of relative paths the directory of the input spreadsheet and the
    directories specified with the ```-I``` CLI parameter are used for the file
    search.
    Although not tested, also URLs to hosted RDF data should be possible instead
    of filenames, due to RDF.rb.
Instead of a hash with object construction parameter, it is also possible to
specify a Ruby proc with arbitrary object construction logic.
This block gets the value of a cell and should return the mapped value to be
used as the object of the corresponding generated triple.

###### ```statement``` parameter
This parameter allows the configuration of the triple generation.
Currently, there are three possible values:
- ```:inverse```:
  Use the subject resource (from the subject column) as the object and the
  mapped value of a cell as the subject of the generated statement.
- ```:restriction```:
  This parameter value makes only sense, when the subject is a OWL class.
  Instead of generating a triple of the form
  ```subject predicate object .```,
  where ```subject``` is the resource from the subject column,
  ```predicate``` is the value specified in the ```predicate``` parameter,
  and ```object``` is the mapped value from column,
  the following statements are generated
```
  subject rdfs:subClassOf [
    rdf:type owl:Restriction ;
    owl:onProperty predicate ;
    restriction_property object
  ] .
```
  ```restriction_property``` is ```owl:hasValue``` by default, but can be
  changed by giving a hash as the value of ```statement``` parameter, containing
  ```:restriction``` as a key and the URI of restriction property as its value.
- ```:none```:
  Don't generate a triple.
  Useful in conjunction with Ruby blocks for custom logic.
  Leaving the ```predicate``` parameter unspecified has the same effect.

###### Custom logic with Ruby blocks
The optional Ruby block can be used to generate further statements (or perform
custom actions in general) to the values of a column.
This block gets the cell value as an argument, but is executed in the context of
the [Cell class](lib/spread2rdf/mapping/cell.rb), so the mapped value can
accessed via the ```object``` method.
It's also possible to access the value or mapped value of another column of the
same row with the methods ```value_of_column``` or ```object_of_column```.
A single statement can be generated with the ```statement``` method, which
expects three arguments for the subject, predicate and object.
Multiple statements at once can be generated with the ```statements``` method,
which takes an arbitrary number of array arguments containing the three subject,
predicate and object elements of a triple.

### Column block definitions
A column block is used to define a sub sheet of a worksheet, meaning a series of
columns (or further columns blocks) which are treated like a sheet, i.e.
introducing subject resources, which are used as the subject of the triples
generated for these columns, while the subjects itself become objects of the
triples for the outer sheet (or column block).

A column block definition consists of
- the keyword ```column_block```,
- followed by a Ruby symbol with an arbitrary name of the column block,
- an optional list of named parameters,
- and a Ruby block with column or further column block definitions.
All parameters of worksheets (except ```start```) and columns (the ```object```
parameter) can be used as parameters of a column block definition.

### Templates
Templates are a way to associate a name with a Ruby block inside a worksheet,
for later reuse of definition blocks or mapping blocks.
A template definition consists of
- the keyword ```template```,
- followed by a name as a Ruby symbol,
- and a block.
After a template definition the block can be accessed directly by using the defined
name.

Example:
```ruby
module Spread2RDF
  Schema.definition 'Example' do
    template :quantity_mapping do |value|
      statements(
          [ object, QUDT.numericValue, value.to_i ],
          [ object, QUDT.unit, object_of_column(:unit) ] )
    end

    worksheet 'Example sheet' do
      column :uri
      column :value, predicate: PSM.parameterMaxQuantity,
                     object:    { uri: :bnode, type: QUDT.QuantityValue },
                     &quantity_mapping
      column :unit, object: unit_mapping # unit_mapping is a predefined custom object mapping to QUDT units
    end
  end
end
```

Another usage for templates is definition of a sequence of columns in worksheet
definition, by calling the ```include``` method with template name (in this case
as Ruby symbol) inside of a worksheet definition (at the appropriate position).

Example:
```ruby
module Spread2RDF
  Schema.definition 'Example' do
    template :default_columns do
      column :name, predicate: RDFS.label
      column :uri
    end

    worksheet 'Example sheet' do
      include :default_columns
    end
  end
end
```

## Executable mappings
It's possible to make a schema mapping definition executable as a command-line
application by placing a ```Schema.execute``` call after the schema definition
in a mapping file.
With that, the mapping file can be used as an executable script file, which
behaves like ```spread2rdf``` with the schema mapping parameter ```-s```
implicitly set to this schema mapping, supporting all of its possible
parameters  (except ```-s``` obviously).

Example: A file ```example-mapping.s2r``` with the following definition
```ruby
#!/usr/bin/env ruby

module Spread2RDF
  Schema.definition 'Example' do
    # ...
  end
  Schema.execute
end
```
can be executed as follows (assuming your system can handle the shebang line or
has Ruby files associated with the ruby interpreter):

    $ example-mapping.s2r example.xls

This call is equivalent to this:

    $ spread2rdf -s example-mapping.s2r example.xls

### Compilation of mappings
An executable mapping can also be compiled to a Windows executable with ```-c```
option of the ```spread2rdf``` command-line interface like this:

    $ spread2rdf -c example-mapping.s2r

The resulting executable can then be used like the executable Ruby mapping file,
but without the need of an installed Ruby, since this is compiled into the
executable.

    $ example-mapping.exe example.xls

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

* Marcel Otto
