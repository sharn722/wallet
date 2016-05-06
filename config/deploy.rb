require "deploy_mailer"

# Change these
server '104.131.2.210', port: 77, roles: [:web, :app, :db], primary: true

set :repo_url,        'git@github.com:sharn722/wallet.git'
set :application,     'wallet'
set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :branch, 'master'

set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.2.4'

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     {  forward_agent: true, :user => fetch(:user), keys: %w('~/.ssh/id_rsa.pub') }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

## Defaults:
# set :scm,           :git
# set :branch,        :master
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

## Linked Files & Directories (Default None):
set :linked_files, %w{config/database.yml config/secrets.yml config/nginx.conf .env}
set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc "Send email notification"
  task :send_notification do
    DeployMailer.deploy_email.deliver_now
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  desc "Make sure all specs pass"
  task :check_specs do
    if scm.to_sym != :git
      abort "Sorry, you can only check specs if you're using git as your scm."
    end
    `git branch` =~ /^\* ([^\s]+)/ or abort "Couldn't understand the output of `git branch`."
    original_branch = $1
    begin
      puts "Checking out #{fetch(:branch)}"
      system("git checkout #{fetch(:branch)}") or raise "Couldn't check out #{fetch(:branch)}."
      puts "Checking specs..."
      system("rake spec") or raise "One or more specs are failing. Come back when they all pass."
      @failed = false
    rescue Exception => e
      puts e
      @failed = true
    ensure
      puts "Going back to branch #{original_branch}"
      system("git checkout #{original_branch}") or abort "Sorry, couldn't put you back to your original branch."
    end
    abort if @failed
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

before "deploy:publishing", "deploy:check_specs"
after "deploy:log_revision", "deploy:send_notification"

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
