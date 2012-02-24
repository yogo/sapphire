$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, 'ruby-1.9.2-p180@passenger'

require "bundler/capistrano"

set :application, "sapphire"
set :scm, :git
set :repository,  "git://github.com/yogo/sapphire.git"
set :branch, "rails_3.0.5"
set :deploy_via, :remote_cache

role :web, "sapphire.rcg.montana.edu"                          # Your HTTP server, Apache/etc
role :app, "sapphire.rcg.montana.edu"                          # This may be the same as your `Web` server
role :db,  "sapphire.rcg.montana.edu", :primary => true # This is where Rails migrations will run

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
  }
}

namespace :sapphire do
  
  namespace :db do
    task :setup do
      run "cd #{current_path} && RAILS_ENV=production bundle exec rake db:setup"
    end

    task :autoupgrade do
      run "cd #{current_path} && RAILS_ENV=production bundle exec rake db:autoupgrade"
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
    end
  end
end

after "deploy:setup",       "sapphire:symlink:setup"
after "deploy:symlink",     "sapphire:symlink:link"
after "deploy:update_code", "sapphire:db:autoupgrade"
