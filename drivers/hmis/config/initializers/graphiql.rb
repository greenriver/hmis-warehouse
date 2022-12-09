if Rails.env.development?
  Rails.configuration.to_prepare do
    # For GraphiQL, sign the current user in as an HMIS user
    GraphiQL::Rails::EditorsController.class_eval do
      before_action do
        sign_in(:hmis_user, current_user)
      end
    end
  end
end
