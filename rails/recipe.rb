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

use :rails_tasks

#######################
# Tasks
#######################

task_for :deploy_to_app_servers, :server => :app_servers do
  git_check_out
  restart_passenger
end

task_for :migrate_db, :server => :background_worker do
  run "cd #{current_dir} && rake db:migrate"
end

#######################
# Sequences
#######################

sequence :full_deploy, :tasks => [:migrate_db, :deploy_to_app_servers]
