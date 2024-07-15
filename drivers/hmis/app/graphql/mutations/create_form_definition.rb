###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateFormDefinition < CleanBaseMutation
    argument :input, Types::Admin::FormDefinitionInput, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(input:)
      # todo @Martha - put this permission check after the check for input.role coming from release-124.
      access_denied! unless current_user.can_manage_forms_for_role?(input.role)

      errors = HmisErrors::Errors.new
      errors.add(:role, :required) if input.role.blank?
      errors.add(:title, :required) if input.title.blank?
      errors.add(:identifier, :required) if input.identifier.blank?
      non_unique_identifier = Hmis::Form::Definition.with_role(input.role).where(identifier: input.identifier).exists?
      errors.add(:identifier, :invalid, message: 'is not unique. Please choose another identifier.') if non_unique_identifier
      return { errors: errors } if errors.any?

      attrs = input.to_attributes
      attrs[:definition] = attrs[:definition] || { item: initial_form_definition_items(attrs[:role]) }

      definition = Hmis::Form::Definition.new(
        version: 0,
        status: Hmis::Form::Definition::DRAFT,
        **attrs,
      )

      raise "Definition invalid: #{definition.errors.full_messages}" unless definition.valid?

      validation_errors = definition.validate_json_form
      return { errors: validation_errors } if validation_errors.any?

      definition.save!
      { form_definition: definition }
    end

    # Basic defaults for some form roles. Future improvements may include:
    # - "locking" fields or attributes that are required, like Assessment Date
    # - allowing the user to choose a template (like "Regular Service" vs "Financial Assistance Service")
    # - managing these "templates" in configuration
    def initial_form_definition_items(role)
      case role.to_sym
      when :SERVICE
        [service_date_provided_item]
      when :CUSTOM_ASSESSMENT
        [section_group(items: [assessment_date_item], num: 1)]
      else
        [{ link_id: 'name', type: 'STRING', text: 'Question Item' }]
      end
    end

    def section_group(items: [], num: 1)
      {
        "text": "Section #{num}",
        "type": 'GROUP',
        "link_id": "section_#{num}",
        "item": items,
      }
    end

    def service_date_provided_item
      {
        "type": 'DATE',
        "link_id": 'date_provided',
        "text": 'Date Provided',
        "required": true,
        "mapping": {
          "field_name": 'dateProvided',
        },
        "bounds": [
          {
            # cannot be before entry date
            "id": 'min-service-date',
            "type": 'MIN',
            "value_local_constant": '$entryDate',
          },
          {
            # cannot be in the future
            "id": 'max-service-date',
            "type": 'MAX',
            "value_local_constant": '$today',
          },
          {
            # cannot be after exit date
            "id": 'max-service-date-exit-date',
            "type": 'MAX',
            "value_local_constant": '$exitDate',
          },
        ],
      }
    end

    def assessment_date_item
      {
        "type": 'DATE',
        "link_id": 'assessment_date',
        "text": 'Assessment Date',
        "required": true,
        "mapping": {
          "field_name": 'assessmentDate',
        },
        "assessment_date": true,
        "bounds": [
          {
            # cannot be before entry date
            "id": 'min-assmt-date',
            "type": 'MIN',
            "value_local_constant": '$entryDate',
          },
          {
            # cannot be in the future
            "id": 'max-assmt-date',
            "type": 'MAX',
            "value_local_constant": '$today',
          },
          {
            # cannot be after exit date
            "id": 'max-assmt-date-exit',
            "type": 'MAX',
            "value_local_constant": '$exitDate',
          },
        ],
      }
    end
  end
end
