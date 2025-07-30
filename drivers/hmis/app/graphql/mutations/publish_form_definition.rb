###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class PublishFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(id:)
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      access_denied! unless current_user.can_manage_forms_for_role?(definition.role)

      raise 'only draft forms can be published' unless definition.draft?

      previous_published_form = Hmis::Form::Definition.find_by(
        identifier: definition.identifier,
        status: Hmis::Form::Definition::PUBLISHED,
      )

      definition.status = Hmis::Form::Definition::PUBLISHED
      # Ensure HUD requirements are set correctly (if applicable). This could mutate the definition.
      definition.set_hud_requirements

      Hmis::Form::Definition.transaction do
        # Retire the previously published version
        previous_published_form&.update!(status: Hmis::Form::Definition::RETIRED)

        # Add any missing custom field keys to the form definition (for new questions)
        cded_generator = Hmis::Form::CustomDataElementGenerator.new(
          definition: definition,
          hud_user: Hmis::Hud::User.from_user(current_user),
          create_missing_mappings: true, # this will mutate the definition JSON to include new CDED mappings
          data_source: GrdaWarehouse::DataSource.hmis.find_by(id: current_user.hmis_data_source_id),
        )
        cdeds = cded_generator.run
        cdeds.each(&:save!)

        # Validate form structure, including HUD requirements
        validation_errors = definition.validate_json_form
        # fixme this should roll back transaction
        return { errors: validation_errors } if validation_errors.any?

        # Save the updated form definition
        definition.save!
      end

      {
        form_identifier: definition,
      }
    end
  end
end
