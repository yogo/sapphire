source 'http://rubygems.org'

gem 'rails'
gem 'sqlite3'
gem 'data_mapper', '1.1.0'
gem 'dm-is-nested_set'
gem 'dm-pager'
#includes yogo-support, yogo-operation, yogo-datamapper
gem 'yogo-support',     :git => "git://github.com/yogo/yogo-support.git"
gem 'yogo-operation',   :git => "git://github.com/yogo/yogo-operation.git"
gem 'yogo-datamapper',  :git => "git://github.com/yogo/yogo-datamapper.git"
gem 'yogo-framework',   :git => "git://github.com/yogo/yogo-framework.git"
gem 'yogo-project',     :git => "git://github.com/yogo/yogo-project.git",
                        :require => 'yogo/project', :ref=>'15d18edc6d81e90e060fa745416a3e7a1d2d0312'

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
gem 'sass'
gem 'tilt'
gem 'rubyzip'

group :development do
  # Deploy with Capistrano
  #gem 'capistrano'
  gem 'rvm-capistrano'
  # To use debugger
  gem 'ruby-debug19', :require => 'ruby-debug'

  #required for theme file generation
  gem 'hpricot'
  gem 'ruby_parser'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
