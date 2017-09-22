module ControllerAuthorization
  extend ActiveSupport::Concern

  delegate *Role.permissions.map{|m| "#{m}?".to_sym}, to: :current_user, allow_nil: true

  # This builds useful methods in the form:
  # require_permission!
  # such as require_can_edit_users!
  # It then checks the appropriate permission against the current user throwing up 
  # an alert if access is blocked
  Role.permissions.each do |permission|
    define_method("require_#{permission}!") do
      not_authorized! unless current_user&.send("#{permission}?".to_sym)
    end
  end

  def require_can_assign_or_view_users_to_clients!
    can_view = can_assign_users_to_clients? || can_view_client_user_assignments?
    return true if can_view    
    not_authorized!
  end

  private def require_can_view_clients_or_window!
    current_user.can_view_client_window? || current_user.can_view_clients?
  end

  def not_authorized!
    redirect_to root_path, alert: 'Sorry you are not authorized to do that.'
  end
end