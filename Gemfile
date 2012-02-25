source 'http://rubygems.org'

gem 'rails', "3.0.5"
gem 'sqlite3'
gem 'data_mapper', '1.1.0'
gem 'dm-is-nested_set'

#includes yogo-support, yogo-operation, yogo-datamapper
gem 'yogo-support',     :git => "git://github.com/yogo/yogo-support.git"
gem 'yogo-operation',   :git => "git://github.com/yogo/yogo-operation.git"
gem 'yogo-datamapper',  :git => "git://github.com/yogo/yogo-datamapper.git"
gem 'yogo-framework',   :git => "git://github.com/yogo/yogo-framework.git"
gem 'yogo-project',     :git => "git://github.com/yogo/yogo-project.git",
                        :require => 'yogo/project'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'uglifier'
end

gem 'jquery-rails'
gem 'dm-rails'
gem 'haml'

group :development do
  # Deploy with Capistrano
  gem 'capistrano'
  
  # Required for the cap deploy (for some reason)
  gem 'archive-tar-minitar'
  gem 'columnize'
  gem 'multi_json', "~> 1.0.0"

  #required for theme file generation
  gem 'web-app-theme'
  gem 'hpricot'
  gem 'ruby_parser'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
