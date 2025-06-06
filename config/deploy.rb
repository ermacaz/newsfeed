require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'newsfeed'
set :domain, 'ermacaz.com'
set :deploy_to, '/var/www/newsfeed'
set :repository, 'git@github.com:ermacaz/newsfeed.git'
set :branch, 'master'
set :rvm_path, '/usr/local/rvm/bin/rvm'
set :rvm_use_path, '/usr/local/rvm/bin/rvm'

# Optional settings:
set :user, 'deploy'          # Username in the server to SSH to.
set :port, '5029'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
set :shared_dirs, fetch(:shared_dirs, []).push('storage')
set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/cable.yml', 'config/master.key')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'
  
  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use', 'ruby-3.4.4@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.5.3 --skip-existing}
  # command %{rvm install ruby-2.5.3}
  # command %{gem install bundler}
end

# task :server do
#   invoke :'rvm:use', 'ruby-3.1.1@default'
#   invoke :'puma:status'
# end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    command %{export PATH=/usr/local/rvm/bin:$PATH}
    command %{export PATH=/usr/local/rvm/gems/ruby-3.4.4/bin:$PATH}
    command %{export PATH=/usr/local/rvm/gems/ruby-3.4.4@global/bin:$PATH}
    command %{export PATH=:/usr/local/rvm/rubies/ruby-3.4.4/bin:$PATH}
    command %{bundle config set --local path 'vendor/bundle'}
    invoke :"bundle:install"
    # command 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RAILS_ENV=production bin/rails db:populate'
    command %{mkdir -p tmp/pids}
    invoke :'deploy:cleanup'
    
    on :launch do
      in_path(fetch(:current_path)) do
        command %{mkdir -p tmp/}
        command %{touch tmp/restart.txt}
      end
    end
  end
  
  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

"Clear all caches on server"
task :wipe_caches do
  command %{cd /var/www/newsfeed/current}
  command %{export PATH=/usr/local/rvm/bin:$PATH}
  command %{export PATH=/usr/local/rvm/gems/ruby-3.4.4/bin:$PATH}
  command %{export PATH=/usr/local/rvm/gems/ruby-3.4.4@global/bin:$PATH}
  command %{export PATH=:/usr/local/rvm/rubies/ruby-3.4.4/bin:$PATH}
  command %{bundle config set --local path 'vendor/bundle'}
  command %{RAILS_ENV=production bin/rails wipe_caches}
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs