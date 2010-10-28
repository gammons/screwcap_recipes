set :stamp, Time.now.utc.strftime("%Y%m%d%H%M.%S")
set :release_dir, "#{deploy_dir}/releases/#{stamp}"
set :current_dir, "#{deploy_dir}/current"
set :shared_dir, "#{deploy_dir}/shared"
set :pid_dir, "#{shared_dir}/pids"

command_set :create_directory_structure do
  run "mkdir -p #{deploy_dir}/shared/pids"
  run "mkdir -p #{deploy_dir}/shared/system"
  run "mkdir -p #{deploy_dir}/shared/log"
end

command_set :after_checkout do
  run "chmod -R g+w #{release_dir}"
  run "rm -rf #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/log #{release_dir}/log"
  run "ln -nfs #{deploy_dir}/shared/system #{deploy_dir}/system"
end

command_set :svn_check_out do
  create_directory_structure
  run "svn co #{svn_url} --username=#{svn_user} --password=#{svn_password} -q #{release_dir}"
  after_checkout
end

command_set :git_check_out do
  create_directory_structure
  run "git clone --depth 10 #{git_url} #{release_dir}"
  after_checkout
end

command_set :do_symlink do
  run "rm -f #{deploy_dir}/current"
  run "ln -s #{release_dir} #{deploy_dir}/current"
end

command_set :restart_mongrels do
  run "for file in #{pid_dir}/*.pid; do mongrel_rails stop -P ${file} 2&>1; sleep 5;  done"
end

command_set :restart_passenger do
  run "touch #{current_dir}/tmp/restart.txt"
end
