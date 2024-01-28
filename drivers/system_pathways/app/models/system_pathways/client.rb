###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Client < GrdaWarehouseBase
    self.table_name = :system_pathways_clients
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    has_many :enrollments, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]
  end
end
