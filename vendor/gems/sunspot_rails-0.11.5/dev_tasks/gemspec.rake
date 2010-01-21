require File.join(File.dirname(__FILE__), '..', '..', 'sunspot', 'lib', 'sunspot', 'gem_tasks')
require File.join(File.dirname(__FILE__), '..', 'lib', 'sunspot', 'rails', 'version')

Sunspot::GemTasks.new do |s|
  s.name = 'sunspot_rails'
  s.version = Sunspot::Rails::VERSION
  s.summary = 'Rails integration for the Sunspot Solr search library'
  s.email = 'mat@patch.com'
  s.homepage = 'http://github.com/outoftime/sunspot_rails'
  s.description = <<TEXT
Sunspot::Rails is an extension to the Sunspot library for Solr search.
Sunspot::Rails adds integration between Sunspot and ActiveRecord, including
defining search and indexing related methods on ActiveRecord models themselves,
running a Sunspot-compatible Solr instance for development and test
environments, and automatically commit Solr index changes at the end of each
Rails request.
TEXT
  s.authors = ['Mat Brown', 'Peer Allan', 'Michael Moen', 'Benjamin Krause']
  s.rubyforge_project = 'sunspot'
  s.files = FileList['[A-Z]*',
                     '{lib,tasks,dev_tasks}/**/*',
                     'generators/**/*',
                     'install.rb',
                     'MIT-LICENSE',
                     'rails/*',
                     'spec/*.rb',
                     'spec/mock_app/{app,lib,db,vendor,config}/**/*',
                     'spec/mock_app/{tmp,log,solr}']
  s.add_dependency 'escape', '>= 0.0.4'
  s.add_dependency 'sunspot', '>= 0.10.6', '<= 0.10.8'
  s.add_development_dependency 'rspec', '~> 1.2'
  s.add_development_dependency 'rspec-rails', '~> 1.2'
  s.add_development_dependency 'ruby-debug', '~> 0.10'
  s.add_development_dependency 'technicalpickles-jeweler', '~> 1.0'
end
