class WarehouseReportsController < ApplicationController
  before_action :require_can_view_any_reports!
  def index

  end

  def report_visible?
    return true if related_report.viewable_by(current_user).exists?
    not_authorized!
  end

  # implment in the specific controller
  # Eventually, this should reference a method on the report model
  # Must respond to `viewable_by`
  def related_report
    raise NotImplementedError
  end
end
