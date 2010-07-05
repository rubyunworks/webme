module WebMe

  # = Erb Rendering Scope
  #
  class Scope

    # New Erb rendering context.
    def initialize(generator)
      @generator = generator
      @config    = generator.config
      @content   = nil
    end

    # Access scope's binding.
    def _binding
      @_binding ||= binding
    end

    def to_binding
      @_binding ||= binding
    end

    # Access to configuration.
    def config
      @config
    end

    # TODO: temporary solution
    attr_accessor :content

    #
    def root
      @generator.root
    end

    #
    def output
      config.output
    end

    #
    def readme
      @generator.readme
    end

    # Access to all of a project's POM metadata.
    def metadata
      @generator.metadata
    end

    # Project title. (Get from generator b/c it can be overrided.)
    def title
      config.title
    end

    # Project name.
    def name
      config.name
    end

    # Project version number.
    def version
      metadata.version
    end

    # README header
    def header
      readme.header
    end

    # README body.
    def body
      readme.body
    end

    # README sections.
    def sections
      readme.sections
    end

    # Logo image file.
    def logo
      @generator.logo
    end

    #
    #def menu
    #  config.menu
    #end

    #
    def resources
      config.resources
    end

    # Advertisement HTML snippet.
    def advert
      config.advert
    end

    # Color pallette.
    def color
      config.color
    end

    # Font.
    def font
      config.font
    end

    # Size.
    def size
      config.size
    end

    # Copyright notice.
    def copyright
      config.copyright
    end

    # Does a file exist in the project?
    def exist?(file)
      root.glob(file).first
    end

    # Render any file in your project.
    # This is mostly for use by custom templates.
    def render(file, options={})
      require 'malt'
      file = root.glob(file, :casefold).first
      file ? Malt.file(file, options).html : ''
    end

    # Read any file in your project.
    # This is mostly for use by custom templates.
    def read(file)
      file = root.glob(file, :casefold).first
      file ? File.read(file) : ''
    end

    # Try the metadata.
    def method_missing(s, *a)
      super(s, *a) unless a.empty?
      metadata.__send__(s)
    end

  end

end

