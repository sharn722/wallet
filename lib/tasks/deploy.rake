namespace :deploy do
  desc "TODO"  
  task notify: :environment do
    DeployMailer.deploy_email.deliver_now
  end
end
