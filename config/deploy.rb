# config valid only for current version of Capistrano
lock '3.16.0'

APP_CONFIG = YAML.load(File.open('config/config.yml'))

set :application, APP_CONFIG['application']
set :repo_url, APP_CONFIG['repository']

set :rvm_ruby_version, '3.2.2'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/apps/#{ fetch(:application) }"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'uploads'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Put maintenance page to the application'
  task :block do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'maintenance:block'
        end
      end
    end
  end

  desc 'Remove maintenance page from the application'
  task :unblock do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'maintenance:unblock'
        end
      end
    end
  end

  task :httpd_graceful do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, "service httpd graceful"
    end
  end

  task :monit do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, "service monit restart"
      execute :sudo, "monit restart delayed_job_all_of_us_helper"
    end
  end
end

after "deploy:updated", "deploy:cleanup"
after "deploy:finished", "deploy:httpd_graceful"
after "deploy:httpd_graceful", "deploy:restart"
after "deploy:restart", "deploy:monit"
