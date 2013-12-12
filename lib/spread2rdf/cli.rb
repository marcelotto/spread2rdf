# coding: utf-8
require 'singleton'

module Spread2RDF
  class Cli
    include Singleton

    attr_accessor :mapping_schema
    
    def run(options = {})
      @running = true
      init(options)
      parse_command_line!
      case
        when compile? then compile(@mapping_schema)
        else convert
      end
      self
    rescue => e
      if Spread2RDF.debug_mode
        raise e
      else
        abort e.to_s
      end
    end

    def init(options)
      @options = options
      @input_file = @options.delete(:input_file) if @options[:input_file]
      self.mapping_schema = @options.delete(:schema) if @options[:schema]
    end
    private :init

    def running?
      @running
    end

    def compile?
      !!@options[:compile]
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

        if not mapping_schema
          opts.on( '-c', '--compile', 'Compile the schema specification to an executable' ) do
            @options[:compile] = true
          end

          opts.on( '-s', '--schema SPEC_FILE', 'Schema specification file (required)' ) do |file|
            if @options[:compile]
              @mapping_schema = file
            else
              self.mapping_schema = file
            end
          end
        end

        @options[:output_dir] ||= '.'
        opts.on( '-o', '--output DIR', "Output directory (default: #{@options[:output_dir]})" ) do |dir|
          abort "Output directory #{dir} doesn't exist" unless compile? or Dir.exist?(dir)
          @options[:output_dir] = dir
        end

        @options[:output_format] ||= 'ttl'
        opts.on( '-f', '--output-format FORMAT', 'Serialization format for the RDF data',
          "FORMAT being one of: nt, n3, ttl, rdf, xml, html, json (default: #{@options[:output_format]})") do |format|
          @options[:output_format] = format.strip.downcase
        end

        opts.on( '-I', '--include DIR', "Add DIR to the search path for external data" ) do |dir|
          raise "Directory #{dir} doesn't exist" unless File.directory?(dir)
          Spread2RDF::SEARCH_PATH.unshift dir
        end

        opts.on( '-d', '--debug', 'Run in debug mode' ) do
          Spread2RDF.debug_mode = true
        end

      end
      optparse.parse!
      if compile?
        @mapping_schema ||= ARGV.first or raise OptionParser::ParseError, 'required schema specification file missing'
      else
        raise OptionParser::ParseError, 'required schema specification file missing' if @mapping_schema.nil?
        @input_file = ARGV.first or @input_file or
            raise OptionParser::ParseError, 'required input file missing'
        SEARCH_PATH << File.expand_path(File.dirname(@input_file))
      end
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

    def convert
      puts "Reading #{@input_file} ..."
      @mapping = mapping_schema.map(@input_file)
      write_output
    end

    def compile(mapping_file)
      output = if File.directory?(@options[:output_dir])
        output_dir = @options[:output_dir]
        output_file = File.basename(mapping_file, File.extname(mapping_file)) + '.exe'
        File.join(output_dir, output_file)
      else
        @options[:output_dir] += '.exe' unless File.extname(@options[:output_dir]) == '.exe'
        @options[:output_dir]
      end
      ocra_options = [
        '--gem-full',
        '--add-all-core',
        '--no-autoload',
        '--no-dep-run',
        '--no-enc',
        '--console'
      ]
      #ocra_options << '--quiet' unless Spread2RDF.debug_mode
      ocra_options << '--debug' if Spread2RDF.debug_mode
      ocra_gemfile = File.join(Spread2RDF::ROOT, 'Gemfile.ocra')
      ocra_options << "--gemfile #{ocra_gemfile}"
      ocra_options << "--output #{output}"
      ocra_cmd = "ocra #{ocra_options.join(' ')} #{mapping_file}"
      puts "compiling #{mapping_file} to #{output}"
      #puts ocra_cmd
      Kernel.system(ocra_cmd)
    end

    self
  end

  CLI = Cli.instance
end
