class WebMe

  # = Erb Rendering Scope
  #
  class Scope

    # Access scope's binding.
    def _binding
      binding
    end

    # New Erb rendering context.
    def initialize(generator)
      @generator = generator
    end

    # Access to all of a project's POM metadata.
    def metadata
      @generator.metadata
    end

    # Project title. (Get from generator b/c it can be overrided.)
    def title
      @generator.title
    end

    # Project name.
    def name
      metadata.name
    end

    # Project version number.
    def version
      metadata.version
    end

    # URL where downloads can be found, or repository.
    def download
      metadata.download || metadata.repository
    end

    # Copyright notice.
    def copyright
      #@copyright ||= (metadata.copyright || "Copyright &copy; #{Time.now.strftime('%Y')}")
      @copyright ||= "Copyright &copy; #{Time.now.strftime('%Y')}"
    end

    # README header
    def header
      @generator.header
    end

    # README body.
    def body
      @generator.body
    end

    # README sections.
    def sections
      @generator.sections
    end

    # Logo image file.
    def logo
      @generator.logo
    end

    # Advertisement HTML snippet.
    def advert
      @generator.advert
    end

    # Color pallette.
    def colors
      @generator.colors
    end

  end

end

