###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Assessment < Types::BaseObject
    include Types::HmisSchema::HasDisabilityGroups
    include Types::HmisSchema::HasCustomDataElements

    available_filter_options do
      arg :type, [Types::Forms::Enums::AssessmentRole]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :project, [ID]
    end

    description 'Custom Assessment'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: true
    field :enrollment_coc, String, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    field :user, HmisSchema::User, null: true
    field :client, HmisSchema::Client, null: false
    field :in_progress, Boolean, null: false
    access_field do
      can :edit_enrollments
      can :delete_enrollments
      can :delete_assessments
    end
    # Related records that were created by this Assessment, if applicable
    field :income_benefit, Types::HmisSchema::IncomeBenefit, null: true
    field :health_and_dv, Types::HmisSchema::HealthAndDv, null: true
    field :exit, Types::HmisSchema::Exit, null: true
    field :disability_group, Types::HmisSchema::DisabilityGroup, null: true
    field :youth_education_status, Types::HmisSchema::YouthEducationStatus, null: true
    field :employment_education, Types::HmisSchema::EmploymentEducation, null: true
    custom_data_elements_field

    field :role, Types::Forms::Enums::AssessmentRole, null: false
    field :definition, Types::Forms::FormDefinition, null: false
    field :wip_values, JsonObject, null: true

    def wip_values
      return unless object.in_progress?

      load_ar_association(object, :form_processor)&.values
    end

    def role
      Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.invert[object.data_collection_stage]&.to_s
    end

    # EXPENSIVE! Do not use in batch
    def definition
      project = load_ar_association(object, :project)

      # If definition is stored on form processor, return that
      # TODO: check if form is retired? For non-WIP assessments, we should
      # really be choosing the "latest" form, which may not be the one on the FormProcessor.
      form_processor = load_ar_association(object, :form_processor)
      definition = load_ar_association(form_processor, :definition) if form_processor
      definition ||= Hmis::Form::Definition.find_definition_for_role(role, project: project)
      definition.filter_context = { project: project }
      definition
    end

    def in_progress
      object.in_progress?
    end

    def income_benefit
      form_processor = load_ar_association(object, :form_processor)
      return unless form_processor.present?

      load_ar_association(form_processor, :income_benefit)
    end

    def health_and_dv
      form_processor = load_ar_association(object, :form_processor)
      return unless form_processor.present?

      load_ar_association(form_processor, :health_and_dv)
    end

    def exit
      form_processor = load_ar_association(object, :form_processor)
      return unless form_processor.present?

      load_ar_association(form_processor, :exit)
    end

    def disability_group
      form_processor = load_ar_association(object, :form_processor)
      return unless form_processor.present?

      # Construct AR scope if Disability records to use for the group
      disability_record_ids = []
      disability_record_ids << form_processor.physical_disability&.id
      disability_record_ids << form_processor.developmental_disability&.id
      disability_record_ids << form_processor.chronic_health_condition&.id
      disability_record_ids << form_processor.hiv_aids&.id
      disability_record_ids << form_processor.mental_health_disorder&.id
      disability_record_ids << form_processor.substance_use_disorder&.id
      disability_record_ids.compact!
      scope = Hmis::Hud::Disability.where(id: disability_record_ids)
      return if scope.empty?

      # Build DisabilityGroup from the scope
      disability_groups = resolve_disability_groups(scope)

      # Error if there is more than one group. Could happen if records have different Data Collection Stages or Information dates or Users, which they shouldn't.
      raise 'Multiple disability groups constructed for one assessment' if disability_groups.size > 1

      disability_groups.first
    end

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
