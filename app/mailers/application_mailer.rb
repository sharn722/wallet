class ApplicationMailer < ActionMailer::Base
  default from: "deploy@wallet.chamalab.com"
  layout 'mailer'
end
