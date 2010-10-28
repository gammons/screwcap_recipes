begin
  require 'rubygems'
  require 'screwcap'
  namespace :remote do
    @deployer = Deployer.new(:recipe_file => File.dirname(__FILE__) + "/../../config/screwcap.rb")
    (@deployer.__tasks + @deployer.__sequences).map {|t| t.__name }.each do |_task|
      desc _task.to_s.humanize
      task _task do
        @deployer.run! _task
      end
    end
  end
rescue LoadError
end
