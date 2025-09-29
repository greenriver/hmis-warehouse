###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaYyaReport
  class Client < GrdaWarehouseBase
    include ::PiiDisplay
    self.table_name = :ma_yya_report_clients
    acts_as_paranoid

    include HasPiiAttributes
    pii_attr :age

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :service_history_enrollment, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', optional: true

    def display_value(header:, value:, pii_policy:)
      pii_value(col: header, raw_value: value, pii_policy: pii_policy)
    end
  end
end
