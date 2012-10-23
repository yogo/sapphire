source 'http://rubygems.org'

gem 'rails'
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

gem 'devise'
gem 'dm-devise'

gem 'jquery-rails'
gem 'dm-rails'
gem 'haml'
gem 'rubyzip'
gem 'newrelic_rpm' #new relic monitoring
group :development do
  # Deploy with Capistrano
  #gem 'capistrano'
  gem 'rvm-capistrano'
  # To use debugger
  gem 'ruby-debug19', :require => 'ruby-debug'

  #required for theme file generation
  gem 'web-app-theme'
  gem 'hpricot'
  gem 'ruby_parser'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
