require 'erb'
require 'malt'

require 'facets/pathname'
require 'facets/ostruct'

require 'pom/project'
require 'pom/readme'

require 'webme/scope'
require 'webme/color'
require 'webme/config'
require 'webme/readme'

module WebMe

  # Generates a basic website based on a README file.
  # It does this by sectioning the README based on 2nd
  # level headers, '==' or '##', ie. <h2>.
  class Generator

    # C O N S T A N T S

    # Relative directory.
    DIR = Pathname.new(File.dirname(__FILE__))

    # Default logo file.
    LOGO = "assets/images/logo.png"

    # C L A S S  M E T H O D S

    #
    def self.templates
      Dir.glob(DIR + "templates/*").map{ |f| File.basename(f) }
    end

    # A T T R I B U T E S

    # Project's root pathname.
    attr :root

    #
    attr :options

    # I N I T I A L I Z E

    #
    def initialize(root, options={})
      @root    = Pathname.new(root)
      @options = OpenStruct.new(options)

      #initialize_defaults

      @config = Config.new(self, @options)

      raise "cannot find README file" unless readme

      #options.each do |k,v|
      #  __send__("#{k}=",v)
      #end

      #config.title    = @options.title    if @options.title
      #config.search   = @options.search   if @options.search
      #config.output   = @options.output   if @options.output
      #config.markup   = @options.markup   if @options.markup
    end

    ##
    #def initialize_defaults
    #  @type     = nil
    #end

    #
    def config
      @config
    end

    #
    def template
      config.template
    end

    # Commanline options for dry-run mode.
    def trial? ; options.trial || $TRIAL ; end

    # Commandline option to trace exectuation.
    def trace? ; options.trace || $TRACE ; end

    # Command-line option to force overwrites.
    def force? ; options.force ; end

    # Name of the project.
    def name
      config.name
    end

    # Output directoy.
    def output
      config.output
    end

    #
    def template_location
      config.template_location
    end

    # Yahoo Application ID.
    def yahoo_id
      config.yahoo_id
    end

    ## Metadata parsed from README file.
    ##
    #def readme_metadata
    #  @readme_metadata ||= POM::Readme.load(root)
    #end

    # POM project
    def project
      @project ||= POM::Project.new(root)
    end

    # POM metadata.
    #
    # We get the metadata in a round about way by
    # first extracting what we can from the README
    # via POM::Readme, then converting that into a
    # POM::Metadata object loading any meta/ entries.
    #
    def metadata
      @metadata ||= (
        project.import_readme unless project.profile.file
        project.metadata
        #readme_metadata.to_metadata(root).load!
        #if (root + 'meta').directory?
        #  POM::Metadata.load(root)
        #else
        #  POM::Metadata.from_readme(root)
        #end
      )
    end

    # README
    def readme
      @readme ||= Readme.new(root, config.type)
    end

    # Generate the website.
    def generate
      transfer
    end

    # Tranfer moves a file from the template location to the site destination.
    # If the file ends in +.erb+ it will be processed by ERB and saved 
    # with with the +.erb+ extension removed. If a file does not end in +.erb+,
    # it will be copied verbatim.
    #--
    # TODO: Use Tilt instead ?
    #++
    def transfer
      if File.directory?(output) && !force?
        $stderr << "Output directory already exists. Use --force to allow overwrite.\n"
        $stderr << "-> #{output.relative_path_from(Pathname.new(Dir.pwd))}\n"
      else
        puts "#{output.relative_path_from(Pathname.new(Dir.pwd))}/"
        fu.mkdir_p(output) unless File.directory?(output)

        tmpdir = template_location.to_s

        entries = Dir.glob("#{tmpdir}/**/*")
        entries = entries.select{ |f| File.file?(f) }

        entries = entries - ["#{tmpdir}/webme.yaml", "#{tmpdir}/webme.yml"]
        entries = entries - ["#{tmpdir}/layout.erb"]

        entries = entries.map{ |f| f.sub(tmpdir + '/', '') }

        #Dir.chdir(DIR + "templates/#{template}") do
        #  entries = Dir['**/*'].select{ |f| File.file?(f) }
        #end

        transfer_logo

        entries.each do |path|
          case File.extname(path)
          when '.erb', '.rhtml'
            puts "  #{path.chomp('.erb')}"
            transfer_erb(path)
          #when '.html', '.css'
          #  transfer_erb(path)
          #when '.layout', '.page', '.post', '.file'  # for Brite
          #  transfer_erb(path)
          else
            puts "  #{path}"
            transfer_copy(path)
          end
        end
      end
    end

    # Copy a file after processing it through Erb.
    def transfer_erb(file)
      txt = erb(template_location + file)
      dir = File.dirname(File.join(output, file))
      fu.mkdir_p(dir) unless File.directory?(dir)
      if File.extname(file) == '.rhtml'
        fname = file.chomp('.rhtml') + '.html'
      else
        fname = file.chomp('.erb')
      end
      if trial?
        puts "erb #{file}"
      else
        File.open(File.join(output,fname), 'w'){ |f| f << txt }
      end
    end

    # Copy a file verbatim.
    def transfer_copy(file)
      dir = File.dirname(File.join(output, file))
      fu.mkdir_p(dir) unless File.directory?(dir)
      fu.cp(template_location + file, File.join(output,file))
    end

    # Helper method to convert file with eRuby.
    def erb(file)
      template = ERB.new(File.read(file))
      content  = template.result(scope.to_binding).to_s
      #content = Malt.file(file).render_deafult(scope._binding).to_s #???
      if config.layout && File.extname(file) == '.rhtml'
        scope.content = content
        content = Malt.file(config.layout).html(scope).to_s
      end
      content
    end

    # Erb rendering scope.
    def scope
      @scope ||= Scope.new(self)
    end

    #
    def transfer_logo
      if config.logo
        dir = output + 'assets/images/'
        fu.mkdir_p(dir) unless dir.exist?
        fu.cp(config.logo, dir)
      end
    end

    # Pull a randomly searched image from the Internet for a logo.
    #
    # Currently this uses BOSSMan to pull from Yahoo Image Search,
    # which requires a Yahoo App ID. Of course, it would be better
    # if it were generic, but you do what you gotta.
    #
    def logo
      @logo ||= (
        if file = output.glob('assets/images/logo.*').first
          file.relative_path_from(output)
        else
          logo_search
        end
      )
    end

    # Logo search using Bossman.
    def logo_search
      return LOGO unless require_bossman
      return LOGO unless yahoo_id
      begin
        BOSSMan.application_id = yahoo_id #<Your Application ID>
        boss = BOSSMan::Search.images("#{search || title}", { :dimensions => "small" })
        if boss.count == "0"
          boss = BOSSMan::Search.images("clipart", { :dimensions => "small" })
        end
        url = boss.results[rand(boss.results.size)].url
        ext = File.extname(url)
        dir = output + "assets/images"
        fu.mkdir_p(dir) unless dir.exist?
        open(url) do |i|
          open(output + "assets/images/logo#{ext}", 'wb') do |o|
            o << i.read
          end
        end
        "assets/images/logo#{ext}"
      rescue
        LOGO
      end
    end

    # Require Bossman library for Yahoo image search.
    def require_bossman
      begin
        require 'bossman'
        require 'open-uri'
        true
      rescue LoadError
        nil
      end
    end

    # Access to FileUtils.
    def fu
      if trial?
        FileUtils::DryRun
      elsif trace?
        FileUtils::Verbose
      else
        FileUtils
      end
    end

=begin
    #--
    # TODO: Integrate some of this into Color class.
    #++

    def calc_colors(hues=nil)
      schema = OpenStruct.new
      case hues
      when Hash
        schema.back = hues['back']
        schema.text = hues['text']
        schema.high = hues['high']
        schema.link = hues['link']
      when String
        color = Color.new(hues)
        schema.back = color
        schema.text = color.lightness > 0.5 ? "#EEEEEE" : "#333333"
        schema.high = color.bright
        schema.link = color.dark #lightness > 0.5 ? text.bright : text.dark
      else
        key = (search+"ZZZ").sub(/[aeiou]/,'')[0,3].upcase.sub(/\W/,'')
        rgb = key.each_byte.to_a.map{ |i| (i-65)*10 }
        color = Color.new(rgb)
        schema.back = color
        schema.text = color.lightness > 0.5 ? "#EEEEEE" : "#333333"
        schema.high = color.bright
        schema.link = color.dark #lightness > 0.5 ? text.bright : text.dark
      end
      schema
    end
=end

  end

end

