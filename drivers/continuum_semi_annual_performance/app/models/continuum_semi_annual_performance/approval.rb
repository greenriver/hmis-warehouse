###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  # Append-only log of approve and unapprove actions; the newest row decides the report's state.
  class Approval < GrdaWarehouseBase
    belongs_to :report, class_name: 'ContinuumSemiAnnualPerformance::Report', foreign_key: :report_instance_id, inverse_of: :approvals
    belongs_to :user, class_name: '::User'

    scope :newest_first, -> { order(created_at: :desc, id: :desc) }

    def action_label
      approved ? 'Approved' : 'Approval Removed'
    end

    def readonly?
      persisted? || super
    end
  end
end
