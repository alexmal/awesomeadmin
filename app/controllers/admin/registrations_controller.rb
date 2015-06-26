class Admin::RegistrationsController < Devise::RegistrationsController
	
	def create
		p = registration_params
		p[:confirmed_at] = Time.now
		build_resource(p)

		if resource.save
			sign_up(resource_name, resource)
			sign_in(resource_name, resource)
			render json: {me: resource, authenticity_token: form_authenticity_token}
		else
			clean_up_passwords
			render json: {error: resource, authenticity_token: form_authenticity_token}
		end
	end

	private

    def registration_params
      params.require(:user).permit(:email, :password, :password_confirmation, :role, :remember_me)
    end
end