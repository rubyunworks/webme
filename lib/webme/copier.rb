require 'pathname'
require 'fileutils'

module WebMe

  class Copier

    # Relative directory.
    DIRECTORY = Pathname.new(File.dirname(__FILE__))

    # Fallback output directory if no other found.
    OUTPUT = 'site'

    # Glob used to lookup output directory.
    OUTPUT_LIST = %w{site website web www}

    #
    def initialize(root, options={})
      @root     = Pathname.new(root)
      @template = options[:template] || 'clean'

      @trial    = options[:trial] || $TRIAL
      @trace    = options[:trace] || $TRACE
      @force    = options[:force]
      @skip     = options[:skip]
    end

    #
    attr :root

    #
    attr :template

    #
    attr_accessor :trial

    #
    attr_accessor :trace

    #
    attr_accessor :force

    #
    attr_accessor :skip

    #
    def template_location
      @template_location ||= (
        DIRECTORY + "templates/#{template}"
      )
    end

    # Commanline options for dry-run mode.
    def trial? ; @trial ; end

    # Commandline option to trace exectuation.
    def trace? ; @trace ; end

    # Command-line option to force overwrites.
    def force? ; @force ; end

    # Command-line option to skip overwrites.
    def skip?  ; @skip ; end

    #
    def action_report
      @report ||= []
    end

    #
    def generate
      copy
      action_report
    end

    #
    def copy
      paths = Dir[self.template_location.to_s + '/**/*']
      dirs, files = paths.partition{ |path| File.directory?(path) }

      return if check_overwrite(files)

      dirs.each do |dir|
        rel = dir.sub(template_location.to_s + '/', '')
        out = self.output + rel
        unless out.exist?
          fileutils.mkdir_p(out)
          action_report << "  mkdir #{out.relative_path_from(root)}"
        end
      end
      files.each do |file|
        rel = file.sub(template_location.to_s + '/', '')
        out = self.output + rel
        if out.exist? && skip?
          action_report << "  skip #{out.relative_path_from(root)}"
        elsif force or !out.exist?
          fileutils.cp(file, out)
          action_report << "  copy #{out.relative_path_from(root)}"
        end
      end
    end

    #
    def check_overwrite(files)
      return false if force?
      return false if skip?
      present = files.map do |file|
        rel = file.sub(template_location.to_s + '/', '')
        out = self.output + rel
        out.exist? ? out : nil
      end.compact
      return false if present.empty?
      files = present.map{ |file| file.relative_path_from(root) }
      raise OverwriteError.new(files)
      true
    end

    #
    def fileutils
      trial? ? FileUtils::DryRun : FileUtils
    end

    # Output directory.
    def output
      @output ||= (
        site = root + OUTPUT_LIST.find{ |path| root + path }
        site = site.relative_path_from(root)
        root + 'gen' + (site || OUTPUT)
      )
    end

  end

  #
  class OverwriteError < StandardError
    def initialize(files)
      super()
      @files = files
    end

    attr :files

    def message
      str = []
      str << "ABORT! The following files already exist:"
      @files.each do |file|
        str << "  #{file}"
      end
      str << "Use the --force or --skip options to bypass this check."
      str.join("\n")
    end
  end

end

