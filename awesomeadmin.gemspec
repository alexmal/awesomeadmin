$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "awesomeadmin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "awesomeadmin"
  s.version     = Awesomeadmin::VERSION
  s.authors     = ["Romaboy"]
  s.email       = ["romadzao@gmail.com"]
  #s.homepage    = "/admin"
  s.summary     = "Summary of Awesomeadmin."
  s.description = "Description of Awesomeadmin."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,public}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.2"

end
