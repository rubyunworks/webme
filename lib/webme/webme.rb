require 'erb'
require 'tilt'

require 'facets/pathname'
require 'facets/ostruct'

require 'pom/metadata'

require 'webme/scope'
require 'webme/color'

# Generates a basic website based on a README file.
# It does this by sectioning the README based on 2nd
# level headers, '==' or '##', ie. <h2>.

class WebMe

  # C O N S T A N T S

  # Relative directory.
  DIR = Pathname.new(File.dirname(__FILE__))

  # Config directory.
  CONFIG_DIR = '{.,}config/webme'

  # Config file, loated at +config/webme.yml+, or standard variations there-of.
  CONFIG = CONFIG_DIR + '/options.{yml,yaml}'

  # Fallback output directory if no other found.
  OUTPUT = 'site'

  # Glob used to lookup output directory.
  OUTPUT_GLOB = '{site,website,web,www}'

  # Defualt template type is +joy+.
  TEMPLATE = 'joy'

  # Default logo file.
  LOGO = "assets/images/logo.png"

  # C L A S S  M E T H O D S

  #
  def self.templates
    Dir.glob(DIR + "templates/*").map{ |f| File.basename(f) }
  end

  # A T T R I B U T E S

  # Template type.
  attr_accessor :template

  # Path to README file.
  attr_accessor :readme

  # Path in which files are placed.
  attr_accessor :output

  # Project title (defaults to POM title).
  attr_accessor :title

  # Use an alternate search term when looking for a logo.
  attr_accessor :search

  # If you want to add an advertisment, you
  # place it here. This should be an HTML snippet.
  attr_accessor :advert

  # Yahoo application id used by Bossman for finding a logo.
  attr_accessor :yahoo_id

  # Colors to use for color scheme.
  attr_accessor :colors

  # Rendereing engine type specified by file extension (eg. +rdoc+ or +markdown+).
  # By default this is picked up by the extension on the README file name,
  # but if none is present or the extension is not the engine type then
  # specifying this manually is necessary.
  attr_accessor :type

  # Force overwrite of pre-exising site.
  attr_accessor :force

  # Run in trial mode.
  attr_accessor :trial

  # Show extra output.
  attr_accessor :trace

  # README header
  attr :header

  # README body
  attr :body

  # README sections
  attr :sections

  # Project's root pathname.
  attr :root

  # I N I T I A L I Z E

  #
  def initialize(root, options={})
    @root = Pathname.new(root)

    initialize_defaults

    raise "cannot find README file" unless readme

    parse_readme

    load_config

    options.each do |k,v|
      __send__("#{k}=",v)
    end

    #@trial    = options[:trial] || $TRIAL
    #@trace    = options[:trace] || $TRACE
    #@force    = options[:force]

    #self.template = options[:template] if options[:template]
    #self.title    = options[:title]    if options[:title]
    #self.search   = options[:search]   if options[:search]
    #self.output   = options[:output]   if options[:output]

    self.colors = nil unless self.colors
  end

  #
  def initialize_defaults
    @template = TEMPLATE
    @output   = root.glob(OUTPUT_GLOB).first || @root + OUTPUT

    @title    = metadata.title #meta(:title)
    @name     = metadata.name  #meta(:project) || meta(:name)
    @search   = metadata.title
    @type     = nil

    @advert   = File.read(advert_file) if advert_file

    @readme   = root.glob('readme{,.*}', :casefold).first
  end

  #
  def trial?
    @trial || $TRIAL
  end

  #
  def trace?
    @trace || $TRACE
  end

  #
  def force?
    @force
  end

  # Name of the project.
  def name
    @name ||= title.downcase.gsub(/\s+/, '_')
  end

  #
  def output=(path)
    @output = Pathname.new(File.expand_path(path))
  end

  #
  def colors=(values)
    @colors = calc_colors(values)
  end

  #
  alias_method :color=, :colors=

  # Generate the website.
  def generate
    transfer
  end

  # Load config file.
  def load_config
    file = root.glob(CONFIG, :casefold).first
    if file
      YAML.load(File.new(file)).each do |k,v|
        __send__("#{k}=",v)
      end
    end
  end

  # Yahoo Application ID is looked for in the working directory and home
  # directory under 'config' or '.config' at 'webme/yahoo.id'. Failing this
  # is looks for 'YAHOO_ID' environment variable.

  def yahoo_id
    @yahoo_id ||= (
      home = Pathname.new(File.expand_path('~'))
      file = root.glob('{,.}config/webme/yahoo.id').first
      file = home.glob('.config/webme/yahoo.id').first unless file
      file ? file.read.strip : ENV['YAHOO_ID']
    )
  end

  # POM metadata.

  def metadata
    @metadata ||= POM::Metadata.load(root)  # TODO: Change to .new ?
  end

  #--
  # TODO: Generalize which files run through Erb.
  # TODO: Use Tilt instead ?
  #++

  def transfer
    if File.directory?(output) && !force?
      $stderr << "Output directory already exists. Use --force to allow overwrite.\n"
      $stderr << "-> #{output.relative_path_from(Pathname.new(Dir.pwd))}\n"
    else
      puts "#{output.relative_path_from(Pathname.new(Dir.pwd))}/"
      fu.mkdir_p(output) unless File.directory?(output)

      tmpdir = (DIR + "templates/#{template}").to_s

      entries = Dir.glob("#{tmpdir}/**/*")
      entries = entries.select{ |f| File.file?(f) }
      entries = entries.map{ |f| f.sub(tmpdir + '/', '') }

      #Dir.chdir(DIR + "templates/#{template}") do
      #  entries = Dir['**/*'].select{ |f| File.file?(f) }
      #end

      entries.each do |path|
        puts "  #{path}"
        case File.extname(path)
        when '.erb'
          transfer_erb(path)
        #when '.html', '.css'
        #  transfer_erb(path)
        #when '.layout', '.page', '.post', '.file'  # for Brite
        #  transfer_erb(path)
        else
          transfer_copy(path)
        end
      end
    end
  end

  # Copy a file after processing it through Erb.

  def transfer_erb(file)
    txt = erb(DIR + "templates/#{template}/#{file}")
    dir = File.dirname(File.join(output, file))
    fu.mkdir_p(dir) unless File.directory?(dir)
    fname = file.chomp('.erb')
    if trial?
      puts "erb #{fname}"
    else
      File.open(File.join(output,fname), 'w'){ |f| f << txt }
    end
  end

  # Copy a file verbatim.

  def transfer_copy(file)
    dir = File.dirname(File.join(output, file))
    fu.mkdir_p(dir) unless File.directory?(dir)
    fu.cp(File.join(DIR, "templates/#{template}", file), File.join(output,file))
  end

  # Helper method to convert file with eRuby.

  def erb(file)
    template = ERB.new(File.read(file))
    template.result(scope._binding)
  end

  # Erb rendering scope.

  def scope
    Scope.new(self)
  end

  # Create html body, sections and header.
  #--
  # TODO: Eventually only support Tilt rendering oif README
  # TODO: Ultimately it would be best to use a real xml parser like Nokigiri.
  #++

  def parse_readme
    abort "No readme file found." unless readme

    type = self.type || File.extname(@readme).sub(/^[.]/,'')
    type = type_heuristics(@readme) if type == ''

    #if require_tilt
      if Tilt[type]
        template = Tilt.new(@readme)
        html = template.render
      else  # fallback
        template = Tilt::RDocTemplate.new(@readme)
        html = template.render
      end
    #else
    #  case type
    #  when 'md', 'markdown'
    #    require_rdiscount
    #    html = markdown(@readme)
    #  else
    #    require_rdoc
    #    html = rdoc(@readme)
    #  end
    #end

    #html = linkify(html)  # no longer needed for rdoc, what about markdown?

    if md = /<h1>(.*?)<\/h1>/.match(html)
      @title = $1 if title.nil? or title.empty?
    end

    i = html.index('<h2>')

    header = html[0...i]
    html[0...i] = ''

    sections = []

    html.gsub!(/<h2>(.*?)<\/h2>/) do |m|
      label = $1.chomp(':')
      ident = label.gsub(/\s+/, '_').downcase
      sections << [ident, label]
      %[</div><div class="section" id="section_#{ident}"><h2>#{label}</h2>]
    end
    html.sub!('</div><div class="section"', '<div class="section"')
    html << '</div>'

    @body = html
    @header = header
    @sections = sections
  end

  # Process the README through rdoc.

  def rdoc(file)
    input = File.read(file)
    markup = ::RDoc::Markup::ToHtml.new
    markup.convert(input)
  end

  # Process the README through markdown.

  def markdown(file)
    input = File.read(file)
    markdown = RDiscount.new(input)
    markdown.to_html
  end

  # NOTE: RDoc no longer needs this. Consider for other markup types if and when supported.

  def linkify(text)
    text.gsub(/((https?\:\/\/)|(www\.))(\S+)(\w{2,4})(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i) do |url|
      full_url = url
      if !full_url.match(/^https?:\/\//)
        full_url = 'http://' + full_url
      end
      '<a href="' + full_url + '">' + url + '</a>'
    end
  end

  # Take the search term and calc uniq colors for it if
  # colors are not already provided.
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

  # Pull a randomly searched image from the Internet for a logo.
  #
  # Currently this uses BOSSMan to pull from Yahoo Image Search,
  # which requires a Yahoo App ID. Of course, it would be better
  # if it were generic, but you do what you gotta.

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

  # Advertisement markup. If not advertisement file is found
  # this will be an empty string.

  def advert
    @advert.to_s
  end

  # Lookup advertisment. First it looks in the destination folder
  # under 'assets/includes/advert.html'. If not found there it
  # looks in the config folder under 'webme/advert.html'.

  def advert_file
    @advert_file ||= output.glob('assets/includes/advert.html').first || root.glob("#{CONFIG_DIR}/advert.html").first
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

  # Require Tilt library if installed.

  def require_tilt
    begin
      require 'tilt'
      true
    rescue LoadError
      false
    end
  end

=begin
  # Require RDoc library.

  def require_rdoc
    begin
      #require 'rdoc/markup'
      require 'rdoc/markup/to_html'
    rescue LoadError
      require 'rubygems'
      require 'rdoc/markup/to_html'
    end
  end

  # Require RDiscount library.

  def require_rdiscount
    require 'rdiscount'
  end
=end

  #--
  # TODO: improve type heuristics
  #++
  def type_heuristics(file)
    text = File.read(file).strip
    return 'rdoc' if /^\=/ =~ text
    return 'md'   if /^\#/ =~ text
    return nil
  end
end

