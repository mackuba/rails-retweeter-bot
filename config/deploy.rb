require 'bundler/capistrano'

set :application, "rails_bot"
set :repository, "git@github.com:mackuba/rails-retweeter-bot.git"
set :scm, :git
set :keep_releases, 5
set :use_sudo, false
set :deploy_to, "/var/www/rails_bot"
set :deploy_via, :remote_cache

server "matterhorn", :app, :web, :db, :primary => true

after 'deploy:update_code', 'deploy:symlink_config'

namespace :deploy do
  task :symlink_config do
    run "ln -s #{shared_path}/config/config.yml #{release_path}/config/config.yml"
  end
end
