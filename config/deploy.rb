$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
require "bundler/capistrano"

set :rvm_ruby_string, 'ruby-1.9.2-p180@passenger'
set :application, "sapphire"
set :scm, :git
set :repository,  "git://github.com/yogo/sapphire.git"
set :branch, "server"
set :deploy_via, :remote_cache


role :web, "sapphire.rcg.montana.edu"
role :app, "sapphire.rcg.montana.edu"
role :db,  "sapphire.rcg.montana.edu", :primary => true

set :use_sudo, false
set :user, "sapphire"
set :deploy_to, "/home/sapphire/rails"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

set :links, {
  :files => %w{
    config/database.yml
  },
  :dirs => %w{
    public/asset_collection
    public/uploads
    tmp/uploads
  }
}

namespace :sapphire do
  namespace :db do
    task :setup do
      run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake db:setup"
    end

    task :autoupgrade do
      run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake db:autoupgrade"
    end
  end
  
  namespace :symlink do
    task :setup do
      links[:dirs].each do |l|
        run "mkdir -p #{deploy_to}/#{shared_dir}/#{l}"
      end
    end

    task :link do
      (links[:files] + links[:dirs]).each do |l|
        run "ln -nfs #{deploy_to}/#{shared_dir}/#{l} #{release_path}/#{l}"
      end
      run "ln -nfs #{release_path}/public/stylesheets/web-app-theme/themes/default/images #{release_path}/public/stylesheets/images"
      run "ln -nfs #{release_path}/public/stylesheets/web-app-theme/themes/default/fonts #{release_path}/public/stylesheets/fonts"
    end
  end
end

after "deploy:setup",       "sapphire:symlink:setup"
after "deploy:symlink",     "sapphire:symlink:link"
after "deploy",             "sapphire:db:autoupgrade"
