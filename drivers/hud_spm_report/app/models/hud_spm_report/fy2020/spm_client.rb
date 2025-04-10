###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2020
  class SpmClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_clients'
    acts_as_paranoid

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :dob
    pii_attr :age
    pii_attr :m1_reporting_age, as: :age
    pii_attr :m2_reporting_age, as: :age
    pii_attr :m3_reporting_age, as: :age
    pii_attr :m4_reporting_age, as: :age
    pii_attr :m5_reporting_age, as: :age
    pii_attr :m6_reporting_age, as: :age
    pii_attr :m7_reporting_age, as: :age

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.column_headings(col)
      case col
      when 'source_client_personal_ids'
        'HMIS Personal IDs'
      else
        human_attribute_name(col)
      end
    end
  end
end
