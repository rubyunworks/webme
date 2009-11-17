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

        opt.on("--template", "-t [NAME]", "select html template") do |name|
          options[:template] = name.downcase
        end

        opt.on("--title [TITLE]", "title to use at top of page") do |title|
          options[:title] = title
        end

        opt.on("--search", "-s [TERM]", "alternate search term for finding a logo") do |term|
          options[:search] = term
        end

        opt.on("--output", "-o [DIR]", "output directory") do |dir|
          options[:output] = dir
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

        opt.on("--help", "-h", "show this help information") do
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

