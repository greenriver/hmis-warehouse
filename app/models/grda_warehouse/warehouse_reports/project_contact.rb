###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ProjectContact < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :report_tokens, foreign_key: :contact_id, class_name: 'GrdaWarehouse::ReportToken'

    validates_email_format_of :email

    def full_name
      "#{first_name} #{last_name}"
    end
  end
end
