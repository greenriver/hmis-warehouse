###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Service < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    description 'HUD or Custom Service rendered'

    def self.configuration
      Hmis::Hud::Service.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, Types::HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :service_type, HmisSchema::ServiceType, null: false
    field :date_provided, GraphQL::Types::ISO8601Date, null: false
    field :fa_amount, Float, null: true
    field :fa_start_date, GraphQL::Types::ISO8601Date, null: true
    field :fa_end_date, GraphQL::Types::ISO8601Date, null: true

    custom_data_elements_field

    # HUD fields
    hud_field :other_type_provided
    hud_field :moving_on_other_type
    hud_field :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided
    hud_field :referral_outcome, HmisSchema::Enums::Hud::PATHReferralOutcome

    # Metadata
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    hud_field :user, HmisSchema::User, null: true

    def user
      load_ar_association(object, :user)
    end

    def type_provided
      [object.record_type, object.type_provided].join(':')
    end

    def sub_type_provided
      return nil unless object.sub_type_provided.present?

      [type_provided, object.sub_type_provided].join(':')
    end

    def service_type
      load_ar_association(object, :custom_service_type)
    end

    # Custom data elements are linked to the underlying record (Hmis::Hud::Service or Hmis::Hud::CustomService)
    # So we pass the record to the resolver.
    def custom_data_elements
      definition_scope = Hmis::Hud::CustomDataElementDefinition.
        for_type(object.owner.class.sti_name).
        for_service_type(object.custom_service_type_id)

      resolve_custom_data_elements(object.owner, definition_scope: definition_scope)
    end
  end
end
