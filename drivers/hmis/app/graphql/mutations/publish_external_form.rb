###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  # Publishes an External Form to its public URL: renders the published version to HTML and uploads it to the public
  # S3 bucket at its external_form_object_key, replacing the live page. This is separate from PublishFormDefinition,
  # so admins can publish a version in the Form Builder and check it before it goes live.
  #
  # @see docs/features/hmis/hmis-external-forms.md
  class PublishExternalForm < CleanBaseMutation
    argument :id, ID, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(id:)
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      access_denied! unless policy_for(definition, policy_type: :form_definition).can_publish?

      raise 'only External Forms can be published to a public URL' unless definition.role == 'EXTERNAL_FORM'
      raise 'only published forms can be published to a public URL' unless definition.published?

      errors = HmisErrors::Errors.new
      if definition.external_form_object_key.blank?
        errors.add(:external_form_object_key, :required, full_message: 'Set the External Form Key before publishing to the public URL.')
        return { errors: errors }
      end

      begin
        HmisExternalApis::PublishExternalFormsJob.new.perform(definition.id)
      rescue StandardError => e
        # The job raises for invalid form content or missing external forms setup, before uploading anything
        Sentry.capture_exception(e)
        errors.add(:base, :server_error, full_message: "Could not publish to the public URL: #{e.message}")
        return { errors: errors }
      end

      { form_identifier: definition }
    end
  end
end
