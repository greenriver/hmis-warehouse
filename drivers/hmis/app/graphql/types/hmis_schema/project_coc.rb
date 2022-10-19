###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectCoc < Types::BaseObject
    include Types::Concerns::HasFields

    def self.configuration
      Hmis::Hud::ProjectCoc.hmis_configuration(version: '2022')
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
        coc_code: {
          field: {},
          argument: {},
        },
        geocode: {
          field: {},
          argument: {},
        },
        address1: {
          field: {},
          argument: {},
        },
        address2: {
          field: {},
          argument: {},
        },
        city: {
          field: {},
          argument: {},
        },
        state: {
          field: {},
          argument: {},
        },
        zip: {
          field: {},
          argument: {},
        },
        geography_type: {
          field: { type: HmisSchema::Enums::GeographyType },
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
