require 'webme'
require 'optparse'

class WebMe

  # = Command-line Utility
  #
  class Command

    # Initialize and run.
    def self.run
      new.run
    end

    # Command-line options in a Hash.
    attr :options

    #
    def initialize
      $TRIAL = nil unless defined?($TRIAL)
      $TRACE = nil unless defined?($TRACE)
    end

    # Parse command-line options.
    def parse
      options = {}

      opts = OptionParser.new do |opt|

        opt.banner = <<-HERE
Usage: webme [OPTIONS]

Generates a basic website based on a README file. It does this
by sectioning the README into tabs based on second level entries
(ie. the <h2>'s produced by == or ##).

If output is not given, generates to the first folder called
website/, web/ or site/ in the current directory. Defaults to
site/ if none of these are found.

OPTIONS:
HERE

        opt.on("--template", "-t NAME", "select html template") do |name|
          options[:template] = name.downcase
        end

        opt.on("--readme", "-r FILE", "README file to use (defaults to first README*)") do |readme|
          options[:readme] = readme
        end

        opt.on("--title TITLE", "title to use at top of page") do |title|
          options[:title] = title
        end

        opt.on("--color HEX", "general color tone, supply a css hex value.") do |hex|
          options[:color] = hex
        end

        opt.on("--font FONT", "font family, eg. times, helvetica, sans-serif.") do |font|
          options[:font] = font
        end

        opt.on("--search", "-s TERM", "alternate term for selecting colors and logo") do |term|
          options[:search] = term
        end

        opt.on("--output", "-o DIR", "output directory") do |dir|
          options[:output] = dir
        end

        opt.on("--type TYPE", "explicate README markup type (rdoc, markdown, etc.)") do |type|
          options[:type] = type
        end

        opt.on("--force", "-f", "force overwrite of pre-existing site") do
          options[:force] = true
        end

        opt.on("--trace", "trace execution") do
          options[:trace] = true
        end

        opt.on("--trial", "run without writing to disk") do
          options[:trial] = true
        end

        opt.on("--debug", "run in debug mode ($DEBUG = true)") do
          $DEBUG   = true
          $VERBOSE = true  # damn it, why isn't this called $WARN ?
        end

        opt.on_tail("--list", "-l", "list available templates") do
          puts WebMe.templates.join("\n")
          exit 0
        end

        opt.on_tail("--help", "-h", "show this help information") do
          puts opt
          exit 0
        end

      end

      opts.parse!

      @options = options
    end

    # Execute command.
    def execute
      readwe = WebMe.new(Dir.pwd, options)
      readwe.generate
    end

    # Parse and execute.
    def run
      parse
      execute
    end
  end

end

