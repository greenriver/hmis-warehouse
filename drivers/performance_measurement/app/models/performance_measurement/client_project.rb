###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class ClientProject < GrdaWarehouseBase
    self.table_name = :pm_client_projects
    acts_as_paranoid

    belongs_to :client, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id], optional: true
    belongs_to :project, primary_key: [:project_id, :report_id], foreign_key: [:project_id, :report_id], optional: true
    has_many :hud_projects, through: :project
    belongs_to :report

    scope :reporting_period, -> do
      where(period: :reporting)
    end

    scope :comparison_period, -> do
      where(period: :comparison)
    end

    scope :for_question, ->(key) do
      where(for_question: key)
    end
  end
end
