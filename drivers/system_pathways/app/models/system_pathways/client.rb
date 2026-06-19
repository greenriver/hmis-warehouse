###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SystemPathways
  class Client < GrdaWarehouseBase
    self.table_name = :system_pathways_clients
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    has_many :enrollments, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]
  end
end
