class DeployMailer < ApplicationMailer
	def deploy_email
		mail(to: 'sharn722@gmail.com', subject: 'App deployed')
	end
end
