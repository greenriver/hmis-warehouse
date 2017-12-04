module WarehouseReportAuthorization
  extend ActiveSupport::Concern
  included do
    before_action :report_visible?
  end
end