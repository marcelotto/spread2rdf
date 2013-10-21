# coding: utf-8

module Spread2RDF
  class Cli
    def initialize
      parse_command_line!
    end

    def run(schema_spec_file = nil)
      schema_spec_file ||= @options[:schema_spec_file]
      abort "No schema specification file given" if schema_spec_file.nil?
      abort "Couldn't find schema specification file #{schema_spec_file}" unless
          File.exist?(schema_spec_file)
      load schema_spec_file
      abort "No schema specification found" if Schema.definitions.empty?
      puts "Reading #{@input_file} ..."
      @mapping = Schema.definitions.first.map(@input_file)
      write_output
      self
    rescue => e
      if Spread2RDF.debug_mode
        raise e
      else
        abort e.to_s
      end
    end

  private

    # Parse command line options
    def parse_command_line!(options={})
      @options = options
      optparse = OptionParser.new do |opts|
        opts.banner = 'Usage: spread2rdf [options] -s SPEC_FILE SPREAD_SHEET_FILE'

        opts.on( '-h', '--help', 'Display this information' ) do
          puts opts
          exit
        end

        opts.on( '-v', '--version', 'Print version information' ) do
          puts "Spread2RDF #{VERSION}"
          exit
        end

        @options[:output_dir] = '.'
        opts.on( '-o', '--output DIR', 'Output directory (default: current directory)' ) do |dir|
          abort "Output directory #{dir} doesn't exist" unless Dir.exist?(dir)
          @options[:output_dir] = dir
        end

        @options[:output_format] = 'ttl'
        opts.on( '-f', '--output-format FORMAT', 'Serialization format for the RDF data',
          "FORMAT being one of: nt, n3, ttl, rdf, xml, html, json (default: ttl)") do |format|
          #format = 'turtle' if format == 'ttl'
          @options[:output_format] = format.strip.downcase
        end

        @options[:schema_spec_file] = nil
        opts.on( '-s', '--schema SPEC_FILE', 'Schema specification file (required)' ) do |file|
          @options[:schema_spec_file] = file
        end

        opts.on( '-d', '--debug', 'Run in debug mode' ) do
          Spread2RDF.debug_mode = true
        end

      end

      optparse.parse!
      raise OptionParser::ParseError, 'required file arguments missing' if ARGV.empty?
      raise OptionParser::ParseError, 'required schema specification file missing' if @options[:schema_spec_file].nil?

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
end