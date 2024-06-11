###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class PublishForm < CleanBaseMutation
    argument :id, ID, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:)
      access_denied! unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition
      raise 'only draft forms can be published' unless definition.status == Hmis::Form::Definition::DRAFT

      previous = Hmis::Form::Definition.where(
        identifier: definition.identifier,
        status: Hmis::Form::Definition::PUBLISHED,
      )

      previous.update(status: 'retired')

      definition.status = 'published'

      if definition.valid?
        definition.save!
        { form_definition: definition }
      else
        errors.add_ar_errors(definition.errors)
        { errors: errors }
      end
    end
  end
end
