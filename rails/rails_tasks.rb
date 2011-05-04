#######################################
# Variables
#######################################

set :stamp, Time.now.utc.strftime("%Y%m%d%H%M.%S")
set :release_dir, "#{deploy_dir}/releases/#{stamp}"
set :current_dir, "#{deploy_dir}/current"
set :shared_dir, "#{deploy_dir}/shared"
set :pid_dir, "#{shared_dir}/pids"

# override these commands to use different source control management type or strategy
set(:scm, :git) unless self.respond_to?(:scm)
set(:strategy, :scm) unless self.respond_to?(:strategy)
set(:app_server, :mongrel) unless self.respond_to?(:app_server)

#######################################
# Base commands
#######################################

command_set :create_directory_structure do
  # ensure these exist
  run "mkdir -p #{deploy_dir}/shared/pids"
  run "mkdir -p #{deploy_dir}/shared/system"
  run "mkdir -p #{deploy_dir}/shared/log"
end

command_set :after_checkout do
  run "chmod -R g+w #{release_dir}"
  run "rm -rf #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/log #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/system #{release_dir}/public/system"
end

command_set :do_symlink do
  run "rm -f #{deploy_dir}/current"
  run "ln -s #{release_dir} #{deploy_dir}/current"
end

command_set :app_rollback do
  run "rm -f #{deploy_dir}/current"
  run "echo \"ln -nfs #{deploy_dir}/releases/\\\`ls #{deploy_dir}/releases/ | tail -n 2 | head -n 1\\\` #{current_dir}\" > /tmp/rollback"
  run "chmod +x /tmp/rollback && /tmp/rollback"
  run "rm -rf /tmp/rollback"
end

#######################################
# SCM-specific checkout commands
#######################################

command_set :svn_check_out do
  run "svn co #{svn_url} --username=#{svn_user} --password=#{svn_password} -q #{release_dir}"
  after_checkout
end

command_set :git_check_out do
  run "git clone --depth 10 #{git_url} #{release_dir}"
  after_checkout
end

command_set :checkout do
  case scm
  when :git
    git_check_out
  when :svn
    svn_check_out
  else
    $stderr << "Unknown source control type.\n"
    Kernel.exit(1)
  end
end

command_set :do_copy do
  local "tar -czvf #{stamp}.tgz ./app  > /dev/null"
  scp :local => "#{stamp}.tgz", :remote => "#{release_dir}/#{stamp}.tgz"
  run "cd #{release_dir} && tar -zxvf #{stamp}.tgz > /dev/null"
  local "rm -rf #{stamp}.tgz"
  run "rm -rf #{release_dir}/#{stamp}.tgz"
end


#######################################
# Application server specific commands
#######################################

command_set :restart_mongrels do
  run "for file in #{pid_dir}/*.pid; do mongrel_rails stop -P ${file} 2&>1; sleep 5;  done"
end

command_set :restart_passenger do
  run "touch #{current_dir}/tmp/restart.txt"
end

command_set :restart_app_server do
  case app_server
  when :mongrel
    restart_mongrels
  when :passenger
    restart_passenger
  end
end

#######################################
# Macro recipes that put it all together
#######################################

command_set :push_code do
  case strategy
  when :scm
    checkout
  when :copy
    run "mkdir -p #{release_dir}"
    do_copy
  end
end

command_set :deploy do
  create_directory_structure
  push_code
  after_checkout
  do_symlink
  restart_app_server
end
