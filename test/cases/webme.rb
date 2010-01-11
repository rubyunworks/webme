require 'webme'

TestCase WebMe do

  Concern "Instantiate and parse"

  Unit :initialize, :parse_readme, :rdoc do
    webme = WebMe.new('test/fixture')
  end


  Concern "Option settings of WebMe instance"

  Unit :root => 'returns root directory setting' do
    webme = WebMe.new('test/fixture')
    webme.root.assert == Pathname.new('test/fixture')
  end

  Unit :force? => 'returns force option' do
    webme = WebMe.new('test/fixture', :force=>true)
    webme.assert.force?
  end

  Unit :trial? => 'returns trial option' do
    webme = WebMe.new('test/fixture', :trial=>true)
    webme.assert.trial?
  end

  Unit :trace? => 'returns trace option' do
    webme = WebMe.new('test/fixture', :trace=>true)
    webme.assert.trace?
  end

  Unit :title => 'returns title option, set manually' do
    webme = WebMe.new('test/fixture', :title=>'Faux Title')
    webme.assert.title == 'Faux Title'
  end

  Unit :output => 'returns default output path' do
    webme = WebMe.new('test/fixture')
    webme.output.assert == Pathname.new("test/fixture/site")
  end

  Unit :readme => '' do
    webme = WebMe.new('test/fixture')
    webme.readme.assert == Pathname.new("test/fixture/README.rdoc")
  end

  Unit :template => 'returns default template name' do
    webme = WebMe.new('test/fixture')
    webme.template.assert == "joy"
  end

  #Unit :initialize_defaults => pass


  Concern "Project metadata"

  Unit :metadata => '' do
    webme = WebMe.new('test/fixture')
    webme.metadata.assert.is_a?(POM::Metadata)
  end

  Unit :name => '' do
    webme = WebMe.new('test/fixture')
    webme.name.assert == ''
  end


  Concern "Parsing of README file"

  Unit :parse_readme => '' do
    pending  # punt :initialize
  end

  Unit :rdoc => '' do
    pending  # punt :initialize
  end

  Unit :markdown => '' do
    pending
  end

  Unit :title => 'returns title option, set from README' do
    webme = WebMe.new('test/fixture')
    webme.assert.title == 'Test Project'
  end

  Unit :header => '' do
    webme = WebMe.new('test/fixture')
    webme.header.assert.start_with? '<h1>Test Project</h1>'
  end

  Unit :body => '' do
    pending
  end

  Unit :sections => '' do
    webme = WebMe.new('test/fixture')
    webme.sections.assert == [["description", "DESCRIPTION"], ["usage", "USAGE"], ["installation", "INSTALLATION"], ["copying", "COPYING"]]
  end



  Unit :load_config => '' do
    pending
  end


  Concern "Calculating a color pallette"

  Unit :calc_colors => '' do
    pending
  end

  Unit :colors => '' do
    pending
  end

  Unit :color= => '' do
    pending
  end






  Concern "Finding a logo image"

  Unit :require_bossman => '' do
    pending
  end

  Unit :yahoo_id => '' do
    pending
  end

  Unit :search => '' do
    pending
  end

  Unit :logo_search => '' do
    pending
  end

  Unit :logo => '' do
    pending
  end


  Concern "Webpage generation"

  Unit :fu => 'FileUtils depends on runmodes' do
    webme = WebMe.new('test/fixture')
    webme.fu.assert == FileUtils
    webme = WebMe.new('test/fixture', :trial=>true)
    webme.fu.assert == FileUtils::DryRun
    webme = WebMe.new('test/fixture', :trace=>true)
    webme.fu.assert == FileUtils::Verbose
  end

  Unit :scope => 'returns Scope object' do
    webme = WebMe.new('test/fixture')
    webme.scope.assert.is_a?(WebMe::Scope)
  end

  Unit :linkify => '' do
    pending
  end

  Unit :transfer_copy => '' do
    pending
  end

  Unit :advert => '' do
    pending
  end

  Unit :transfer => '' do
    pending
  end

  Unit :transfer_erb => '' do
    pending
  end

  Unit :generate => '' do
    pending
  end

  Unit :erb => '' do
    pending
  end

end

