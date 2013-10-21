# coding: utf-8
require 'rubygems/package'

require 'optparse'

require 'active_support/core_ext'
require 'awesome_print'

require 'roo'
require 'spread2rdf/extensions/roo_xlsm_fix'

require 'linkeddata'

require 'spread2rdf/attributes'
require 'spread2rdf/version'
require 'spread2rdf/helper'
require 'spread2rdf/coord'
require 'spread2rdf/namespace'
require 'spread2rdf/roo_helper'

require 'spread2rdf/schema/schema'
require 'spread2rdf/schema/statement_mapping_schema'
require 'spread2rdf/schema/element'
require 'spread2rdf/schema/spreadsheet'
require 'spread2rdf/schema/sheet'
require 'spread2rdf/schema/column_block'
require 'spread2rdf/schema/worksheet'
require 'spread2rdf/schema/column'
require 'spread2rdf/schema/sheet_dsl'
require 'spread2rdf/schema/spreadsheet_dsl'

require 'spread2rdf/mapping/element'
require 'spread2rdf/mapping/statement'
require 'spread2rdf/mapping/sheet'
require 'spread2rdf/mapping/spreadsheet'
require 'spread2rdf/mapping/worksheet'
require 'spread2rdf/mapping/column_block'
require 'spread2rdf/mapping/resource'
require 'spread2rdf/mapping/column'
require 'spread2rdf/mapping/cell'


require 'spread2rdf/cli'

module Spread2RDF
  class << self
    attr_accessor :debug_mode
  end
end

