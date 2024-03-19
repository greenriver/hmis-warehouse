###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceType < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    graphql_name 'ServiceType'

    available_filter_options do
      arg :search_term, String
      arg :include_hud_services, Boolean
      # ADD: category
    end

    field :id, ID, null: false
    field :name, String, null: false
    field :hud, Boolean, null: false, method: :hud_service?
    field :supports_bulk_assignment, Boolean, null: false, default_value: false
    field :hud_record_type, HmisSchema::Enums::Hud::RecordType, null: true
    field :hud_type_provided, HmisSchema::Enums::ServiceTypeProvided, null: true
    field :category, String, null: false
    field :form_definitions, [Forms::FormDefinition], null: false, description: 'Definitions that are specified for this service type'

    # object is a Hmis::Hud::CustomServiceType

    def category
      category_record.name
    end

    def hud_type_provided
      return unless object.hud_service?

      [object.hud_record_type, object.hud_type_provided].join(':')
    end

    def form_definitions
      raise 'unauthorized' unless current_user.can_configure_data_collection?

      definitions_for_type = load_ar_association(object, :definitions)
      definitions_for_category = load_ar_association(category_record, :definitions)
      (definitions_for_type + definitions_for_category).uniq.sort_by(&:id)
    end

    protected def category_record
      load_ar_association(object, :custom_service_category)
    end
  end
end
