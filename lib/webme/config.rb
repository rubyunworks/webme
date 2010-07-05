module WebMe

  class Config

    # Relative directory.
    DIR = Pathname.new(File.dirname(__FILE__))

    # Fallback output directory if no other found.
    OUTPUT = 'site'

    # Glob used to lookup output directory.
    OUTPUT_GLOB = '{site,website,web,www}'

    # Config directory.
    CONFIG_DIR = '{.webme,.config/webme}'

    # Config file, loated at +config/webme.yml+, or standard variations there-of.
    CONFIG = CONFIG_DIR + '/config.{yml,yaml}'

    # Defualt template type is +clean+.
    TEMPLATE = 'clean'

    # Defualt font.
    FONT = 'helvetica, sans-serif'

    # Default font size.
    SIZE = '16px'

    #
    def initialize(controller, options)
      @controller = controller

      @template = TEMPLATE
      @font     = FONT
      @size     = SIZE

      @name     = metadata.name
      @title    = metadata.title
      @search   = metadata.title

      @output   = default_output
      @color    = keyword_color

      @template = options.template if options.template
      @title    = options.title    if options.title
      @search   = options.search   if options.search
      @output   = options.output   if options.output
      @type     = options.markup   if options.markup

      load_config
    end

    #
    def root
      @controller.root
    end

    #
    def options
      @controller.options
    end

    #
    def metadata
      @controller.metadata
    end

    # Project title (defaults to POM title).
    attr_accessor :title

    #
    attr_writer :name
 
    #
    def name
      @name ||= title.downcase.gsub(/\s+/, '_')
    end

    # Use an alternate search term when looking for a logo.
    attr_accessor :search

    # Path in which files are placed.
    attr_reader :output

    #
    def output=(path)
      @output = Pathname.new(File.expand_path(path))
    end

    # README type (rdoc, markdown).
    attr_accessor :type

    # Template type.
    attr_accessor :template

    # Font to use.
    attr_accessor :font

    # Relative font size.
    attr_accessor :size

    # Primary color to use for color scheme.
    attr_reader :color

    #
    def color=(c)
      @color = Color.new(c)
    end

    # Menu lookup corresponds to POM::Resources.
    # It is a has of resource name and labels.
    attr_writer :menu

    #
    def menu
      @menu #||= (
        #srcs = metadata.resources.to_h
        #srcs.delete('home')
        #srcs
      #)
    end

    #
    def resources
      if @menu
        @menu.map do |name, label|
          next if name =~ /^home/
          url = metadata.resources.__send__(name)
          if url
            [label, url]
          end
        end
      else
        h = {}
        h['docs'] = metadata.resources.docs if metadata.resources.docs
        h['wiki'] = metadata.resources.wiki if metadata.resources.wiki
        h['api']  = metadata.resources.api  if metadata.resources.api
        h['mail'] = metadata.resources.mail if metadata.resources.mail
        h['repo'] = metadata.resources.repo if metadata.resources.repo
        h['bugs'] = metadata.resources.bugs if metadata.resources.bugs
        h
      end
    end

    # Yahoo Application ID used by Bossman for finding a logo.
    # Yahoo Application ID is looked for in the home directory under
    # '.config/webme/yahoo.id'. Failing this is looks for 'YAHOO_ID'
    # environment variable.
    def yahoo_id
      @yahoo_id ||= (
        home = Pathname.new(File.expand_path('~'))
        file = home.glob('.config/webme/yahoo.id').first
        file = home.glob('.config/yahoo.id').first unless file
        file ? file.read.strip : ENV['YAHOO_ID']
      )
    end

    # Copyright notice.
    def copyright
      #@copyright ||= (metadata.copyright || "Copyright &copy; #{Time.now.strftime('%Y')}")
      @copyright ||= "Copyright &copy; #{Time.now.strftime('%Y')}"
    end

    ## If you want to add an advertisment, you
    ## place it here. This should be an HTML snippet.
    #attr_accessor :advert

    # Advertisement markup. If not advertisement file is found
    # this will be an empty string.
    def advert
      @advert ||= advert_file ? File.read(advert_file) : ''
    end

    # Lookup advertisment. First it looks in the destination folder
    # under 'assets/includes/advert.html'. If not found there it
    # looks in the config folder under 'webme/advert.html'.
    def advert_file
      @advert_file ||= (
        output.glob('assets/includes/advert.html').first || 
        root.glob("#{CONFIG_DIR}/advert.html").first
      )
    end

    # Logo file.
    def logo
      @logo ||= Dir.glob(CONFIG_DIR + '/logo.*').first
    end

    #
    def layout
      @layout ||= template_location.glob('layout.erb').first
    end

    #
    def config
      @config ||= root.glob(CONFIG_DIR)
    end

    #
    def template_location
      @template_location ||= (
        dir = nil
        if template == 'custom'
          dir = config.glob('template/').first
          dir = dir.chomp('/') if dir
          dir = dir || (DIR + "templates/#{TEMPLATE}")
        else
          dir = (DIR + "templates/#{template}")
        end
        dir
      )
    end

  private

    # Load config file.
    def load_config
      load_template_config
      load_project_config
    end

    # Load template default configuration.
    def load_template_config
      file = Dir.glob("#{template_location}/webme.{yaml,yml}").first
      if file
        YAML.load(File.new(file)).each do |k,v|
          __send__("#{k}=",v)
        end
      end
    end

    # Load per-project configuration.
    def load_project_config
      file = root.glob(CONFIG, :casefold).first
      if file
        YAML.load(File.new(file)).each do |k,v|
          __send__("#{k}=",v)
        end
      end
    end

    # Determine output directory.
    def default_output
      root.glob(OUTPUT_GLOB).first || root + OUTPUT
    end

    # Take the search term and calc a uniq color.
    def keyword_color
      key = (search+"ZZZ").sub(/[aeiou]/,'')[0,3].upcase.sub(/\W/,'')
      rgb = key.each_byte.to_a.map{ |i| (i-65)*10 }
      Color.new(rgb)
    end

  end

end

