Rails.configuration.to_prepare do
  # Add before_action to GraphiQL to sign the current user in as an HMIS user.
  # This controller is only used in development.
  GraphiQL::Rails::EditorsController.class_eval do
    before_action do
      sign_in(:hmis_user, current_user)
    end
  end
end
