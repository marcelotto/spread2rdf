# coding: utf-8
require 'singleton'

module Spread2RDF
  class Cli
    include Singleton

    attr_accessor :mapping_schema
    
    def run(options = {})
      @running = true
      @options = options
      @input_file = @options.delete(:input_file) if @options[:input_file]
      self.mapping_schema = @options.delete(:schema) if @options[:schema]
      parse_command_line!
      puts "Reading #{@input_file} ..."
      @mapping = mapping_schema.map(@input_file)
      write_output
      self
    rescue => e
      if Spread2RDF.debug_mode
        raise e
      else
        abort e.to_s
      end
    end

    def running?
      @running
    end

    def mapping_schema=(schema)
      @mapping_schema =
        case schema
          when nil then nil
          when Schema::Spreadsheet then schema
          when String
            abort "no schema specification file given" if schema.nil?
            abort "couldn't find schema specification file #{schema}" unless
                File.exist?(schema)
            load schema
            abort "no schema specification found" if Schema.definitions.empty?
            Schema.definitions.first
          else raise ArgumentError
        end
    end

  private

    # Parse command line options
    def parse_command_line!
      optparse = OptionParser.new do |opts|
        if mapping_schema
          opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] SPREAD_SHEET_FILE"
        else
          opts.banner = 'Usage: spread2rdf [options] -s SPEC_FILE SPREAD_SHEET_FILE'
        end

        opts.on( '-h', '--help', 'Display this information' ) do
          puts opts
          exit
        end

        opts.on( '-v', '--version', 'Print version information' ) do
          puts "Spread2RDF #{VERSION}"
          exit
        end

        @options[:output_dir] ||= '.'
        opts.on( '-o', '--output DIR', "Output directory (default: #{@options[:output_dir]})" ) do |dir|
          abort "Output directory #{dir} doesn't exist" unless Dir.exist?(dir)
          @options[:output_dir] = dir
        end

        @options[:output_format] ||= 'ttl'
        opts.on( '-f', '--output-format FORMAT', 'Serialization format for the RDF data',
          "FORMAT being one of: nt, n3, ttl, rdf, xml, html, json (default: #{@options[:output_format]})") do |format|
          #format = 'turtle' if format == 'ttl'
          @options[:output_format] = format.strip.downcase
        end

        opts.on( '-s', '--schema SPEC_FILE', 'Schema specification file (required)' ) do |file|
          self.mapping_schema = file
        end unless mapping_schema

        opts.on( '-d', '--debug', 'Run in debug mode' ) do
          Spread2RDF.debug_mode = true
        end

      end

      optparse.parse!
      raise OptionParser::ParseError, 'required file arguments missing' if ARGV.empty?
      raise OptionParser::ParseError, 'required schema specification file missing' if mapping_schema.nil?

      @input_file = ARGV.first
    rescue OptionParser::ParseError => e
      puts e.message
      puts optparse.help
      exit
    end

    def output_filename
      output_dir = @options[:output_dir]
      name = File.basename(@input_file, File.extname(@input_file))
      "#{output_dir}/#{name}.#{@options[:output_format]}"
    end

    def write_output
      filename = output_filename
      abort 'No RDF data to write!' if @mapping.try(:graph).blank?
      graph = @mapping.graph
      puts "Writing #{graph.count} RDF statements to #{filename} ... "
      # TODO: base_uri: ... for writer constructor
      RDF::Writer.open(filename) do |writer|
        RDF::Vocabulary.each do |vocabulary|
          writer.prefix vocabulary.__prefix__, vocabulary.to_s
        end
        Namespace.namespace.each do |name, namespace|
          writer.prefix name.to_s.downcase, namespace.to_s
        end
        graph.each_statement { |statement| writer << statement }
      end
    end
    self
  end

  CLI = Cli.instance
end