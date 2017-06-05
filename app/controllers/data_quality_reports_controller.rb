class DataQualityReportsController < ApplicationController
  # Autorize by either access to projects OR access by token
  skip_before_action :authenticate_user!
  before_action :require_valid_token_or_project_access!

  def show

  end

  def require_valid_token_or_project_access!
    if params[:notification_id].present?
      token = GrdaWarehouse::ReportToken.find_by_token(params[:notification_id])
      raise ActionController::RoutingError.new('Not Found') if token.blank?
      return true if token.valid?
    else
      return require_can_view_projects!
    end
    raise ActionController::RoutingError.new('Not Found')
  end
end