module AuthenticationHelper
  def authenticate user
    request.env['HTTPS'] = 'on'
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end
end
