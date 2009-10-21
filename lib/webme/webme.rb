require 'erb'

require 'facets/pathname'
require 'pom/metadata'

require 'webme/color'

# Generates a basic website based on a README
# file. It does this by sectioning the README
# based on '==', ie. <h2>.
#
# TODO: Add markdown support.
#
# TODO: Need clean eRuby rendering context.
#
class WebMe

  # Relative directory.
  DIR = Pathname.new(File.dirname(__FILE__))

  # Config file. Loated at +config/readwe.yml+, or standard variations thereof.
  CONFIG = '{.,}config/webme/options.{yml,yaml}'

  # Fallback output directory if no other found.
  OUTPUT = 'site'

  # Glob used to lookup output directory.
  OUTPUT_GLOB = '{site,web,website,www}'

  # Defualt template type is +joy+.
  TEMPLATE = 'joy'

  # Template type.
  attr_accessor :template

  # Run in trial mode.
  attr_accessor :trial

  # Show extra output.
  attr_accessor :verbose

  # Path to README file.
  attr_accessor :readme

  # Path in which files are placed.
  attr_accessor :output

  # Project title.
  attr_accessor :title

  # Copyright notice.
  attr_accessor :copyright

  # Yahoo application id used by Bossman for finding a logo.
  attr_accessor :yahoo_id

  # Use an alternate search term when looking for a logo.
  attr_accessor :search

  # Colors to use for color scheme.
  attr_accessor :colors

  # If you want to add an advertisment, you
  # place it here. This should be an HTML snippet.
  attr_accessor :advert

  # Name of the project.
  attr :name

  # Project's root pathname.
  attr :root

  #
  def initialize(root, options={})
    @root      = Pathname.new(root)

    # DEFAULTS

    @template  = TEMPLATE
    @output    = @root.glob(OUTPUT_GLOB).first || @root + OUTPUT

    @name      = metadata.name #meta(:project) || meta(:name)
    @title     = metadata.title #meta(:title)
    #@copyright = metadata.copyright

    @logo =(
      file = @output.glob('assets/images/logo.*').first
      file.basename if file
    )

    @advert =(
      file = @output.glob('assets/includes/advert.html').first
      file.read if file
    )

    @readme = @root.glob((options[:readme] || 'readme{,.*}'), :casefold).first

    raise "cannot find README file" unless @readme

    parse_readme

    load_config

    @trial    = options[:trial]
    @verbose  = options[:verbose]

    @template = options[:template] if options[:template]
    @output   = options[:output]   if options[:output]
    @title    = options[:title]    if options[:title]
    @search   = options[:search]   if options[:search]

    calc_colors
  end

  #
  def yahoo_id
    @yahoo_id ||= (
      home = Pathname.new(File.expand_path('~'))
      file = @root.glob('{,.,#{home}/.}config/webme/yahoo.id').first
      file = file || home.glob('.config/webme/yahoo.id').first
      file ? file.read : ENV['YAHOO_ID']
    )
  end

  #
  def metadata
    @project ||= POM::Metadata.new(root)
  end

  # Load config file.
  def load_config
    file = @root.glob(CONFIG, :casefold).first
    if file
      YAML.load(File.new(file)).each do |k,v|
        __send__("#{k}=",v)
      end
    end
  end

  # Copyright notice.
  def copyright
    #@copyright ||= (metadata.copyright || "Copyright &copy; #{Time.now.strftime('%Y')}")
    @copyright ||= "Copyright &copy; #{Time.now.strftime('%Y')}"
  end

  # Version number.
  def version
    metadata.version
  end

  # URL where downloads can be found, or repository.
  def download
     metadata.download || metadata.repository
  end

  # Generate the website.
  def generate
    transfer
  end

 private

  # Read a project meta entry.
  #
  # TODO: Use POM library in the future.
  #def meta(name)
  #  if file = @root.glob("{.,}meta/#{name}").first
  #    file.read.strip
  #  end
  #end

  #
  def transfer
    fu.mkdir_p(output) unless File.directory?(output)
    entries = []
    Dir.chdir(DIR + "template/#{template}") do
      entries = Dir['**/*'].select{ |f| File.file?(f) }
    end
    entries.each do |path|
      case File.extname(path)
      when '.html'
        transfer_erb(path)
      when '.css'
        transfer_erb(path)
      else
        transfer_copy(path)
      end
    end
  end

  #
  def transfer_erb(file)
    txt = erb(DIR + "template/#{template}/#{file}")
    fu.mkdir_p(File.dirname(File.join(output, file)))
    if trial
      puts "erb #{file}"
    else
      File.open(File.join(output,file), 'w'){ |f| f << txt }
    end
  end

  def transfer_copy(file)
    fu.mkdir_p(File.dirname(File.join(output, file)))
    fu.cp(File.join(DIR, "template/#{template}", file), File.join(output,file))
  end

  # Convert file with eRuby.
  def erb(file)
    template = ERB.new(File.read(file))
    template.result(binding)
  end

  attr :header

  attr :body

  attr :sections

  # Create html body, sections and header.
  def parse_readme
    abort "No readme file found." unless readme

    html = rdoc(@readme)

    if md = /<h1>(.*?)<\/h1>/.match(html)
      @title ||= $1
    end

    html = linkify(html)

    i = html.index('<h2>')

    header = html[0...i]
    html[0...i] = ''

    sections = []

    html.gsub!(/<h2>(.*?)<\/h2>/) do |m|
      label = $1
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

  #
  def linkify(text)
    text.gsub(/((https?\:\/\/)|(www\.))(\S+)(\w{2,4})(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i) do |url|
      full_url = url;
      if !full_url.match(/^https?:\/\//)
        full_url = 'http://' + full_url
      end
      '<a href="' + full_url + '">' + url + '</a>'
    end
  end

  #
  def rdoc(file)
    require 'rdoc/markup/simple_markup'
    require 'rdoc/markup/simple_markup/to_html'
    input = File.read(file)
    markup = SM::SimpleMarkup.new
    format = SM::ToHtml.new
    markup.convert(input, format)
  end

  # TODO: Add markdown support.
  def markdown()
  end

  # Take the title and calc uniq colors for it.
  def calc_colors
    if @colors
      back = @colors['back']
      text = @colors['text']
      high = @colors['high']
      link = @colors['link']
      color = Color.new(back)
    else
      @colors = {}
      key = (title+"ZZ").sub(/[aeiou]/,'')[0,3].upcase.sub(/\W/,'')
      rgb = key.each_byte.to_a.map{ |i| (i-65)*10 }
      color = Color.new(rgb)
    end

    back ||= color
    text ||= color.lightness > 0.5 ? "#333333" : "#EEEEEE"
    high ||= color.bright
    link ||= color.dark #lightness > 0.5 ? text.bright : text.dark

    @colors[:back] = "##{back}"
    @colors[:text] = "##{text}"
    @colors[:high] = "##{high}"
    @colors[:link] = "##{link}"
  end

  # Pull a randomly searched image from the Net for a logo.
  def logo
    return nil unless require_bossman
    return nil unless yahoo_id
    @logo ||= (
      BOSSMan.application_id = yahoo_id #<Your Application ID>

      boss = BOSSMan::Search.images("#{search || title}", { :dimensions => "small" })
      if boss.count == "0"
        boss = BOSSMan::Search.images("clipart", { :dimensions => "small" })
      end

      url = boss.results[rand(boss.results.size)].url

      #require 'net/http'
      #Net::HTTP.start("static.flickr.com") { |http|
      #  resp = http.get("/92/218926700_ecedc5fef7_o.jpg")
      #  open("fun.jpg", "wb") { |file|
      #    file.write(resp.body)
      #   }
      #}

      ext = File.extname(url)

      open(url) do |i|
        open(output + "assets/images/logo#{ext}", 'wb') do |o|
          o << i.read
        end
      end

      "logo#{ext}"
    )
  end

  #
  def require_bossman
    begin
      require 'bossman'
      require 'open-uri'
      true
    rescue LoadError
      nil
    end
  end

  # Default advert.
  def advert
    return '' if FalseClass === @advert
    @advert ||= <<-HERE
  <script type="text/javascript"><!--
  google_ad_client = "pub-1126154564663472";
  /* RUBYWORKS 09-10-02 728x90 */
  google_ad_slot = "0788888658";
  google_ad_width = 728;
  google_ad_height = 90;
  //-->
  </script>
  <script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
  </script>
    HERE
  end

  # Access to FileUtils.
  def fu
    if trial
      FileUtils::DryRun
    elsif verbose
      FileUtils::Verbose
    else
      FileUtils
    end
  end

end

