require 'webme'

TestCase WebMe do

  Concern "Settings of WebMe instance" do
    @webme = WebMe.new('test/fixtures/rdoc', :title=>'Faux Title', :force=>true, :trial=>true, :trace=>true)
  end

  Unit :root => 'returns root directory setting' do
    @webme.root.assert == Pathname.new('test/fixtures/rdoc')
  end

  Unit :force? => 'returns force option' do
    @webme.assert.force?
  end

  Unit :trial? => 'returns trial option' do
    @webme.assert.trial?
  end

  Unit :trace? => 'returns trace option' do
    @webme.assert.trace?
  end

  Unit :title => 'returns title option, set manually' do
    @webme.assert.title == 'Faux Title'
  end

  Unit :output => 'returns default output path' do
    @webme.output.assert == Pathname.new("test/fixtures/rdoc/site")
  end

  Unit :readme => '' do
    @webme.readme.assert == Pathname.new("test/fixtures/rdoc/README.rdoc")
  end

  Unit :template => 'returns default template name' do
    @webme.template.assert == "joy"
  end

  Unit :advert => '' do
    raise Pending
  end

  #Unit :initialize_defaults => pass


  Concern "Parsing of RDoc-based README file"

  Unit :parse_readme => '', :rdoc => '' do
    @webme = WebMe.new('test/fixtures/rdoc')
  end

  Unit :title => 'returns title option, set from README' do
    @webme.assert.title == 'Test Project'
  end

  Unit :header => 'isolates the header' do
    @webme.header.assert.start_with? '<h1>Test Project</h1>'
  end

  Unit :body => ''

  Unit :sections => '' do
    @webme.sections.assert == [["description", "DESCRIPTION"], ["usage", "USAGE"], ["installation", "INSTALLATION"], ["copying", "COPYING"]]
  end


  Concern "Parsing of Markdown-based README file"

  Unit :markdown => '', :parse_readme => '' do
    @webme = WebMe.new('test/fixtures/markdown')
  end

  Unit :title => 'returns title option, set from README' do
    @webme.title.assert == 'Test Project'
  end

  Unit :header => 'returns README header in HTML form' do
    @webme.header.assert.start_with? '<h1>Test Project</h1>'
  end

  Unit :body => 'returns README body in HTML form' do
    @webme.body.assert.start_with? %[<div class="section"]
    @webme.body.assert.end_with? %[</div>]
  end

  Unit :sections => 'returns a list if the body sections' do
    @webme.sections.assert == [["description", "DESCRIPTION"], ["usage", "USAGE"], ["installation", "INSTALLATION"], ["copying", "COPYING"]]
  end

  Unit :linkify => ''


  Concern "Project metadata"

  Unit :metadata => '' do
    webme = WebMe.new('test/fixtures/rdoc')
    webme.metadata.assert.is_a?(POM::Metadata)
  end

  Unit :name => '' do
    webme = WebMe.new('test/fixtures/rdoc')
    webme.name.assert == 'test_project'
  end


  Concern "Configuration file"

  Unit :load_config => 'is called on instantiation' do
    @webme = WebMe.new('test/fixtures/config')
  end

  Unit :title => 'can be set by configuration file' do
    @webme.title = "Configured Title"
  end



  Concern "Calculating a color pallette"

  Unit :calc_colors => '' do
    webme = WebMe.new('test/fixtures/rdoc')
    colors = webme.calc_colors
    colors.link.to_s.assert == "#7D7D7D"
    colors.text.to_s.assert == "#EEEEEE"
    colors.back.to_s.assert == "#FAFAFA"
    colors.high.to_s.assert == "#FDFDFD"
  end

  Unit :colors => '' do
    webme = WebMe.new('test/fixtures/rdoc')
    webme.colors.link.to_s.assert == "#7D7D7D"
    webme.colors.text.to_s.assert == "#EEEEEE"
    webme.colors.back.to_s.assert == "#FAFAFA"
    webme.colors.high.to_s.assert == "#FDFDFD"
  end

  #Unit :color= => '' do
  #  pending
  #end


  Concern "Finding a logo image"

  Unit :require_bossman => '' do
    raise Pending
  end

  Unit :yahoo_id => '' do
    webme = WebMe.new('test/fixtures/config')
    webme.yahoo_id == "0123456789"
  end

  Unit :search => '' do
    raise Pending
  end

  Unit :logo_search => '' do
    raise Pending
  end

  Unit :logo => '' do
    raise Pending
  end


  Concern "Website generation and transfer"

  Unit :fu => 'FileUtils depends on runmodes' do
    webme = WebMe.new('test/fixtures/rdoc')
    webme.fu.assert == FileUtils
    webme = WebMe.new('test/fixtures/rdoc', :trial=>true)
    webme.fu.assert == FileUtils::DryRun
    webme = WebMe.new('test/fixtures/rdoc', :trace=>true)
    webme.fu.assert == FileUtils::Verbose
  end

  Unit :scope => 'returns Scope object' do
    webme = WebMe.new('test/fixtures/rdoc')
    webme.scope.assert.is_a?(WebMe::Scope)
  end

  Unit :transfer => '' do
    raise Pending
  end

  Unit :transfer_copy => '' do
    raise Pending
  end

  Unit :transfer_erb => '' do
    raise Pending
  end

  Unit :generate => '' do
    raise Pending
  end

  Unit :erb => '' do
    raise Pending
  end

end

