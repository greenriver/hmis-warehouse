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

  def require_can_view_clients_or_window!
    can_view = current_user.can_view_client_window? || current_user.can_view_clients?
    return true if can_view    
    not_authorized!
  end

  def require_window_file_access!
    can_view = current_user.can_see_own_file_uploads? || current_user.can_manage_window_client_files?
    return true if can_view    
    not_authorized!
  end

  def require_can_access_vspdat_list!
    return true if GrdaWarehouse::Vispdat.any_visible_by?(current_user)    
    not_authorized!
  end

  def require_can_create_or_modify_vspdat!
    return true if GrdaWarehouse::Vispdat.any_modifiable_by(current_user)
    not_authorized!
  end

  def require_can_edit_window_client_notes_or_own_window_client_notes!
    return true if current_user.can_edit_window_client_notes? || current_user.can_see_own_window_client_notes?
    not_authorized!
  end

  def require_can_view_all_reports!
    return true if current_user.can_view_all_reports?
  end

  def require_can_assign_reports!
    return true if current_user.can_assign_reports?
    not_authorized!
  end

  def require_can_see_this_client_demographics!
    return true if current_user.can_view_client_window?
    # attempt to set the client various ways
    if params[:client_id].present?
      set_client_from_client_id
    elsif params[:id].present?
      set_client
    end
    return true if @client.show_window_demographic_to?(current_user)
    not_authorized!
  end

  def not_authorized!
    redirect_to root_path, alert: 'Sorry you are not authorized to do that.'
  end

  def check_release
    return true unless GrdaWarehouse::Config.get(:window_access_requires_release)
    if @client.release_expired?
      flash[:alert] = "Client #{@client.full_name} is not viewable due to an expired/missing signed release"
      redirect_to window_clients_path
    end
  end
end
