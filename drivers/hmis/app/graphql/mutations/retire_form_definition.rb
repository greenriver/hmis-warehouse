###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  # Retires a form: its published version becomes retired, so the form identifier has no published version.
  # Existing records collected with the form stay editable. A retired External Form's external_form_object_key
  # can be reused by another form.
  #
  # @see docs/features/hmis/hmis-form-definitions.md#lifecycle For the full status lifecycle
  class RetireFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(id:)
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      access_denied! unless policy_for(definition, policy_type: :form_definition).can_publish?

      raise 'only published forms can be retired' unless definition.published?

      # A draft would still count as an active version of the form, so require it to be resolved first
      draft_exists = Hmis::Form::Definition.where(identifier: definition.identifier, data_source_id: definition.data_source_id).draft.exists?
      if draft_exists
        errors = HmisErrors::Errors.new
        errors.add(:base, :invalid, full_message: 'This form has an unpublished draft. Delete or publish the draft before retiring the form.')
        return { errors: errors }
      end

      # TODO: retiring an External Form should also take its published page down from the public S3 bucket
      # (HmisExternalApis::PublishExternalFormsJob uploads it). Until then the page stays live, and submissions
      # to it are still processed, until another form is published to the same external_form_object_key.
      definition.update!(status: Hmis::Form::Definition::RETIRED)

      { form_identifier: definition }
    end
  end
end
