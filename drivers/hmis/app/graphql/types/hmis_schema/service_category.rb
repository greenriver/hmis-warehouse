###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceCategory < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata
    include Types::Admin::HasFormRules

    graphql_name 'ServiceCategory'
    field :id, ID, null: false
    field :name, String, null: false
    field :hud, Boolean, null: false, deprecation_reason: 'No longer used'
    field :service_types, HmisSchema::ServiceType.page_type, null: false
    form_rules_field

    # object is a Hmis::Hud::CustomServiceCategory

    def service_types
      load_ar_association(object, :service_types)
    end

    def hud # TODO(#5737) - Remove
      service_types.all?(&:hud_service?)
    end

    def form_rules(**args)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      scope = Hmis::Form::Instance.for_service_category_by_entities(object.id)
      resolve_form_rules(scope, **args)
    end
  end
end
