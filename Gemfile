source 'http://rubygems.org'

gem 'rails', '3.2'
gem 'sqlite3'
gem 'data_mapper', '1.2.0'
gem 'dm-is-nested_set'
gem 'dm-pager'
gem 'dm-types', :git => "https://github.com/datamapper/dm-types.git", :ref=>"613cc5698874bb7a55603e196e1923157e96df08"
gem 'dm-core', :git => "git@github.com:scleveland/dm-core.git", :ref=>"59ad47cd52f55b99ad7d4f181803c651ec4ea287"
#includes yogo-support, yogo-operation, yogo-datamapper
gem 'yogo-support',     :git => "git://github.com/yogo/yogo-support.git"
gem 'yogo-operation',   :git => "git://github.com/yogo/yogo-operation.git"
gem 'yogo-datamapper',  :git => "git://github.com/yogo/yogo-datamapper.git", :ref=>"5db8c6d4d38e3ecb731c2e3a03921d7e5eed7e29"
gem 'yogo-framework',   :git => "git://github.com/yogo/yogo-framework.git"
gem 'yogo-project',     :git => "git://github.com/yogo/yogo-project.git",
                        :require => 'yogo/project', :ref=>'e95fdcf788dc376e47766924843e3cb851d76551'

gem 'faraday'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'uglifier'
end

gem 'devise', '2.0'#'1.4.2'
gem 'dm-devise'
gem 'jquery-rails'
gem 'dm-rails'
gem 'haml'
gem 'sass'
gem 'tilt'
gem 'rubyzip'
gem 'curb'
gem 'seafile_api', :git => "https://github.com/scleveland/seafile_api.git", :ref=>"e4b88c4617db7e58090ab93920f543458784b6e5"

group :development do
  # Deploy with Capistrano
  #gem 'capistrano'
  #gem 'rvm-capistrano'
  # To use debugger
  #gem 'ruby-debug19', :require => 'ruby-debug'

  #required for theme file generation
  gem 'hpricot'
  gem 'ruby_parser'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
