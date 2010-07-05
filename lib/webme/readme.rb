module WebMe

  #
  class Readme

    #
    def initialize(root, markup=nil)
      @root   = root
      @markup = markup
      @file   = root.glob('readme{,.*}', :casefold).first

      parse_readme
    end

    # Rendereing engine markup type specified by file extension (eg. +rdoc+ or +markdown+).
    # By default this is picked up by the extension on the README file name,
    # but if none is present or the extension is not the engine type then
    # specifying this manually is necessary.
    attr :markup

    # Path to README file.
    attr :file

    # README title
    attr :title

    # README header
    attr :header

    # README body
    attr :body

    # README sections
    attr :sections

    # Create html body, sections and header.
    #--
    # TODO: Ultimately it would be best to use a real xml parser like Nokigiri.
    #++
    def parse_readme
      abort "No readme file found." unless file

      type = self.markup || File.extname(file)
      type = type_heuristics(@readme) if markup == ''

      html = Malt.file(file, :type=>type).html.to_s

      #if engine = Tilt[markup]
      #  template = engine.new(file)
      #  html = template.render
      #else  # fallback
      #  template = Tilt::RDocTemplate.new(file)
      #  html = template.render
      #end

      #html = linkify(html)  # no longer needed for rdoc, what about markdown?

      if md = /<h1>(.*?)<\/h1>/.match(html)
        @title = $1
      end

      i = html.index('<h2>')
      i = 0 unless i

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

    #--
    # TODO: improve type heuristics
    #++
    def type_heuristics(file)
      text = File.read(file).strip
      return '.rdoc' if /^\=/ =~ text
      return '.md'   if /^\#/ =~ text
      return nil
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

  end

end
