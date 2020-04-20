###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ControllerAuthorization
  extend ActiveSupport::Concern

  delegate(*Role.permissions.map { |m| "#{m}?".to_sym }, to: :current_user, allow_nil: true)

  # This builds useful methods in the form:
  # require_permission!
  # such as require_can_edit_users!
  # It then checks the appropriate permission against the current user throwing up
  # an alert if access is blocked
  (Role.permissions + User.additional_permissions).each do |permission|
    define_method("require_#{permission}!") do
      not_authorized! unless current_user&.send("#{permission}?".to_sym)
    end
  end

  def require_can_see_this_client_demographics!
    return true if current_user.can_view_client_window?

    # attempt to set the client various ways
    if params[:client_id].present?
      set_client_from_client_id
    elsif params[:id].present?
      begin
        set_client
      rescue ActiveRecord::RecordNotFound
        not_authorized!
        return false
      end
    end
    return true if @client.show_window_demographic_to?(current_user)

    not_authorized!
  end

  def not_authorized!
    your_root_path = root_path
    your_root_path = current_user.my_root_path if current_user
    redirect_to(your_root_path, alert: 'Sorry you are not authorized to do that.')
  end

  # This should no longer be needed
  # We can rely on searchable_by and viewable_by scopes on Client
  def check_release
    return true unless GrdaWarehouse::Config.get(:window_access_requires_release)
    return true if can_view_clients? || can_see_clients_in_window_for_assigned_data_sources?
    return true if @client&.consent_form_valid?

    flash[:alert] = "Client #{@client&.full_name} is not viewable due to an expired/missing signed release"
    redirect_to clients_path
  end
end
