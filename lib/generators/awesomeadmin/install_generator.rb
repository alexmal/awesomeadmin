module Awesomeadmin
  class InstallGenerator < Rails::Generators::Base
    desc 'Awesomeadmin installation generator'

    def install
      route("mount Awesomeadmin::Engine => '/admin'")
    end
  end
end