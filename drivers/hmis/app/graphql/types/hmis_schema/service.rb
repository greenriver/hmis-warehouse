###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Service < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata
    include Types::HmisSchema::HasCustomDataElements

    description 'HUD or Custom Service rendered'

    def self.configuration
      Hmis::Hud::Service.hmis_configuration(version: '2024')
    end

    # NOTE: there may be class load-order dependent issues in development/test
    available_filter_options do
      arg :service_category, [ID]
      arg :service_type, [ID]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :project, [ID]
      arg :date_provided, GraphQL::Types::ISO8601Date
    end

    field :id, ID, null: false
    field :enrollment, Types::HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :service_type, HmisSchema::ServiceType, null: false
    field :date_provided, GraphQL::Types::ISO8601Date, null: true
    field :fa_amount, Float, null: true
    field :fa_start_date, GraphQL::Types::ISO8601Date, null: true
    field :fa_end_date, GraphQL::Types::ISO8601Date, null: true

    custom_data_elements_field

    # HUD fields
    hud_field :other_type_provided
    hud_field :moving_on_other_type
    hud_field :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided
    hud_field :referral_outcome, HmisSchema::Enums::Hud::PATHReferralOutcome

    field :record_type, HmisSchema::Enums::Hud::RecordType, null: true
    field :type_provided, HmisSchema::Enums::ServiceTypeProvided, null: true

    def type_provided
      [object.record_type, object.type_provided].join(':')
    end

    def sub_type_provided
      return nil unless object.sub_type_provided.present?

      [type_provided, object.sub_type_provided].join(':')
    end

    def service_type
      custom_service_types_scope = Hmis::Hud::CustomServiceType.where(data_source_id: object.data_source_id)
      case object.owner_type
      when 'Hmis::Hud::Service'
        dataloader.with(Sources::CustomServiceTypeByHudTypeSource).
          load([object.RecordType, object.TypeProvided])
      when 'Hmis::Hud::CustomService'
        load_ar_scope(scope: custom_service_types_scope, id: object.custom_service_type_id)
      else
        raise
      end
    end

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def custom_data_elements
      owner_service = load_ar_association(object, :owner)
      resolve_custom_data_elements(owner_service)
    end
  end
end
