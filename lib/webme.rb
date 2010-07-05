require 'webme/generator'

module WebMe
  VERSION="1.3.0" #:till: VERSION="<%= version %>"

  def self.new(root, options)
    Generator.new(root, options)
  end

end



