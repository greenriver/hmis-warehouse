###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class PublishFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :newly_published, Types::Forms::FormDefinition, null: false
    field :newly_retired, Types::Forms::FormDefinition, null: true
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

      Hmis::Form::Definition.transaction do
        previous_published_form&.update!(status: Hmis::Form::Definition::RETIRED)
        definition.save!
      end

      {
        newly_published: definition,
        newly_retired: previous_published_form,
        form_identifier: definition,
      }
    end
  end
end
