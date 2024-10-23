###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
    begin
      return false unless set_client # return if set client generates a redirect
      return true if @client&.show_demographics_to?(current_user)
    rescue ActiveRecord::RecordNotFound
      # ignore records we can't see
    end

    not_authorized!
    return false
  end

  protected def not_authorized!(message = nil)
    raise NotAuthorizedError, message
  end

  included do
    rescue_from 'NotAuthorizedError', with: :handle_unauthorized_error
  end

  protected def handle_unauthorized_error(error)
    respond_to do |format|
      format.html do
        location = current_user&.my_root_path || root_path
        redirect_to(location, alert: error.message)
      end
      format.any { head :forbidden }
    end
  end
end
