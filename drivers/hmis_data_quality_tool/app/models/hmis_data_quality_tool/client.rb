###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Client < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    def self.detail_headers
      {
        destination_client_id: 'Warehouse Client ID',
        first_name: 'First Name',
        last_name: 'Last Name',
        personal_id: 'HMIS Personal ID',
        dob: 'DOB',
        dob_data_quality: 'DOB Data Quality',
        male: 'Male',
        female: 'Female ',
        no_single_gender: 'No Single Gender',
        transgender: 'Transgender',
        questioning: 'Questioning',
        am_ind_ak_native: 'American Indian, Alaska Native, or Indigenous',
        asian: 'Asian or Asian American',
        black_af_american: 'Black, African American, or African',
        native_hi_pacific: 'Native Hawaiian or Pacific Islander',
        white: 'White',
        race_none: 'Race None',
      }.freeze
    end
  end
end
