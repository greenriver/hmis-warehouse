###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Client < GrdaWarehouseBase
    self.table_name = :pm_clients
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report
    has_many :client_projects, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]
  end
end
