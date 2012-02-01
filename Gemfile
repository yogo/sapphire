source 'http://rubygems.org'

gem 'rails'
gem 'sqlite3'
gem 'dm-sqlite-adapter'
gem 'dm-postgres-adapter'

#includes yogo-support, yogo-operation, yogo-datamapper
gem 'yogo-support',     :git => "git://github.com/yogo/yogo-support.git"
gem 'yogo-operation',   :git => "git://github.com/yogo/yogo-operation.git"
gem 'yogo-datamapper',  :git => "git://github.com/yogo/yogo-datamapper.git"
gem 'yogo-project',     :git => "git://github.com/yogo/yogo-project.git", 
                        :require => 'yogo/project'
gem 'yogo-framework',   :git => "git://github.com/yogo/yogo-framework.git"

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'dm-rails'
gem 'haml'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
