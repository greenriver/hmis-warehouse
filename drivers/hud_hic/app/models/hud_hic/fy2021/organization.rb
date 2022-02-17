###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Fy2021
  class Organization < ::GrdaWarehouseBase
    self.table_name = 'hud_report_hic_organizations'
    include ::HMIS::Structure::Organization
    acts_as_paranoid

    has_many :report_organizations, as: :universe_membership, dependent: :destroy
    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.from_attributes_for_hic(organization)
      new(organization.for_export.attributes.slice(*hmis_configuration(version: '2022').keys.map(&:to_s)))
    end

    # Hide ID, move client_id, and name to the front
    def self.detail_headers
      special = ['OrganizationID', 'OrganizationName']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        [h, h.humanize]
      end.to_h
    end
  end
end
