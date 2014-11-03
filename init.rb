require 'redmine'

require 'redmine_stats/redmine_stats'

Redmine::Plugin.register :redmine_stats do
  name 'Redmine Stats plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end


# RedmineApp::Application.config.after_initialize do
  
# end