class Admin::SessionsController < Devise::SessionsController
	def create
		self.resource = warden.authenticate!(auth_options)
		sign_in(resource_name, resource)
		render json: {me: resource, authenticity_token: form_authenticity_token}
	end
end