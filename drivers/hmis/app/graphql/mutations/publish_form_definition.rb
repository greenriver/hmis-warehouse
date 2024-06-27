###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class PublishFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: false

    def resolve(id:)
      access_denied! unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition
      raise 'only draft forms can be published' unless definition.draft?

      previous_published_form = Hmis::Form::Definition.find_by(
        identifier: definition.identifier,
        status: Hmis::Form::Definition::PUBLISHED,
      )

      definition.status = Hmis::Form::Definition::PUBLISHED

      validation_errors = definition.validate_json_form
      return { errors: validation_errors } if validation_errors.any?

      Hmis::Form::Definition.transaction do
        previous_published_form&.update!(status: Hmis::Form::Definition::RETIRED)
        definition.save!
      end

      {
        form_identifier: definition,
      }
    end
  end
end
