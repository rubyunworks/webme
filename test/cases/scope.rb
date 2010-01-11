require 'webme'

TestCase WebMe::Scope do

  Concern "The Scope should reflect attributes of",
          "it's WebMe parent visible to templates."

  Unit :initialize => '' do
    @webme = WebMe.new('test/fixtures/config')
    @scope = @webme.scope
  end

  Unit :version => '' do
    @scope.version.assert == @webme.metadata.version
  end

  Unit :_binding => '' do
    @scope._binding.eval('self').assert == @scope
  end

  Unit :download => '' do
    @scope.download.assert == @webme.metadata.download
  end

  Unit :colors => '' do
    @scope.colors.assert == @webme.colors
  end

  Unit :title => '' do
    @scope.title.assert == @webme.title
  end

  Unit :sections => '' do
    @scope.sections.assert == @webme.sections
  end

  Unit :body => '' do
    @scope.body.assert == @webme.body
  end

  Unit :metadata => '' do
    @scope.metadata.assert == @webme.metadata
  end

  Unit :copyright => '' do
    #@scope.copyright.assert == @webme.metadata.copyright
    @scope.copyright.assert == "Copyright &copy; #{Time.now.strftime('%Y')}"
  end

  Unit :advert => '' do
    @scope.advert.assert == @webme.advert
  end

  Unit :name => '' do
    @scope.name.assert == @webme.name
  end

  Unit :header => '' do
    @scope.header.assert == @webme.header
  end

  Unit :logo => '' do
    @scope.logo.assert == @webme.logo
  end

end

