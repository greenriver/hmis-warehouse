###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# CustomDataElementDefinitions.find(key)
module HmisExternalApis::AcHmis::Importers::Loaders
  class CustomDataElementDefinitions
    attr_accessor :data_source_id, :system_user_id
    def initialize(data_source_id:, system_user_id:)
      self.data_source_id = data_source_id
      self.system_user_id = system_user_id
    end

    def find_or_create(owner_type:, key:)
      config = configs.detect { |i| owner_type == i.fetch(:owner_type) && key.to_sym == i.fetch(:key) }
      raise "CDE definition not found #{config.inspect}" unless config

      Hmis::Hud::CustomDataElementDefinition
        .where(config.merge(data_source_id: data_source_id))
        .first_or_create! { |r| r.user_id = system_user_id }
    end

    protected

    def configs
      [
        # Project: direct_entry
        { owner_type: 'Hmis::Hud::Project', field_type: :boolean, key: :direct_entry, label: 'Direct Entry' },
        # Enrollment: rental_assistance_end_date
        { owner_type: 'Hmis::Hud::Enrollment', field_type: :date, key: :rental_assistance_end_date, label: 'Rental Assistance End Date', at_occurrence: true },
        # Enrollment: esg_allowance_grant_referred
        { owner_type: 'Hmis::Hud::Enrollment', field_type: :string, key: :esg_allowance_grant_referred, label: 'ESG Allowance Grant Referred' },

        # Enrollment: esg_allowance_grant_received
        { owner_type: 'Hmis::Hud::Enrollment', field_type: :integer, string: :esg_allowance_grant_received, label: 'ESG Allowance Grant Received' },

        # Enrollment: esg_allowance_grant_received_amount
        { owner_type: 'Hmis::Hud::Enrollment', field_type: :float, key: :esg_allowance_grant_received_amount, label: 'ESG Allowance Grant Received Amount' },

        # Enrollment: esg_allowance_grant_reason_not_referred
        { owner_type: 'Hmis::Hud::Enrollment', field_type: :string, key: :esg_allowance_grant_reason_not_referred, label: 'ESG Allowance Grant Reason Not Referred' },

        # Enrollment: reason_for_exit_type
        { owner_type: 'Hmis::Hud::Exit', field_type: :string, key: :reason_for_exit_type, label: 'Voluntary Exit or an Involuntary Termination' },

        # Enrollment: reason_for_exit_voluntary
        { owner_type: 'Hmis::Hud::Exit', field_type: :string, key: :reason_for_exit_voluntary, label: 'Voluntary Exit Reason' },

        # Enrollment: reason_for_exit_involuntary
        { owner_type: 'Hmis::Hud::Exit', field_type: :string, key: :reason_for_exit_involuntary, label: 'Involuntary Termination Reason' },

        # Enrollment: reason_for_exit_other
        { owner_type: 'Hmis::Hud::Exit', field_type: :string, key: :reason_for_exit_other, label: 'Other Exit Reason' },

        # IncomeBenefit: federal_poverty_level
        { owner_type: 'Hmis::Hud::IncomeBenefit', field_type: :string, key: :federal_poverty_level, label: 'Federal Poverty Level' },
      ]
    end
  end
end
