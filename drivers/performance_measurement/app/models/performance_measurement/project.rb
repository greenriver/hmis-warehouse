###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Project < GrdaWarehouseBase
    self.table_name = :pm_projects
    acts_as_paranoid

    belongs_to :report
    belongs_to :hud_project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: :project_id, optional: true
    has_many :client_projects, primary_key: [:project_id, :report_id], foreign_key: [:project_id, :report_id]

    scope :reporting_period, -> do
      where(reporting_period: true)
    end

    scope :comparison_period, -> do
      where(comparison_period: true)
    end
  end
end
