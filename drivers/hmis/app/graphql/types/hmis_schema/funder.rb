###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Funder < Types::BaseObject
    include Types::Concerns::HasFields

    def self.configuration
      Hmis::Hud::Funder.hmis_configuration(version: '2022')
    end

    def self.type_fields
      {
        id: {
          field: { type: ID, null: false },
        },
        project: {
          field: { type: Types::HmisSchema::Project, null: false },
          argument: { name: :project_id, type: ID },
        },
        funder: {
          field: { type: HmisSchema::Enums::FundingSource },
          argument: {},
        },
        other_funder: {
          field: {},
          argument: {},
        },
        grant_id: {
          field: {},
          argument: {},
        },
        start_date: {
          field: { null: false },
          argument: {},
        },
        end_date: {
          field: {},
          argument: {},
        },
        date_created: {
          field: {},
        },
        date_updated: {
          field: {},
        },
        date_deleted: {
          field: {},
        },
      }.freeze
    end

    add_fields
  end
end
