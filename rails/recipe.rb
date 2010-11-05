#######################
# Servers
#######################

gateway :dev_gateway, :address => "dev.server.com", :user => "root", :keys => "~/.ssh/dev_key"
server :app_servers, :addresses => ["10.1.10.1", "10.1.10.2"], :user => "root", :keys => "~/.ssh/app_key", :gateway => :dev_gateway
server :background_worker, :address => "background.server.com", :user => "root", :password => "xxx"

#######################
# Variables and includes
#######################

set :deploy_dir, "/mnt/rails/myapp"
set :git_url, "git@dev.myapp.com:myapp.git"
set :git_branch, "release"

# The default scm is git.  Uncomment below to use subversion.
#set :scm, :svn

# The default deployment strategy is to use a scm checkout.
# uncomment below to use the copy strategy, which will tar up your current directory,
# send it to the remote, and untar it.
#set :strategy, :copy

# use the standard rails tasks file, available for study in config/screwcap/rails_tasks.rb 
use :rails_tasks

#######################
# Tasks
#######################

task :deploy_to_app_servers, :server => :app_servers do
  # take a look at the deploy macro task recipe here:
  # https://github.com/gammons/screwcap_recipes/blob/master/rails/rails_tasks.rb#L117
  deploy 
end

task :migrate_db, :server => :background_worker do
  run "cd #{current_dir} && rake db:migrate"
end

#######################
# Sequences
#######################

sequence :full_deploy, :tasks => [:migrate_db, :deploy_to_app_servers]
