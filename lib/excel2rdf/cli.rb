# coding: utf-8

module Excel2RDF
  class Cli
    def initialize
      parse_command_line!
    end

  private

    # Parse command line options
    def parse_command_line!(options={})
      @options = options
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: excel2rdf [options] FILES"

        opts.on( '-h', '--help [ACTION]', 'Display this screen or the description of action specific parameters' ) do |action_name|
          puts opts
          exit
        end

        @options[:output_dir] = nil
        opts.on( '-o', '--output DIR', 'Output directory' ) do |dir|
          @options[:output_dir] = dir
        end


      end
      optparse.parse!
      raise OptionParser::ParseError, 'required file arguments missing' unless ARGV.present?

      @input_files = ARGV
    rescue OptionParser::ParseError => e
      puts e.message
      puts optparse.help
      exit
    end

  end
end