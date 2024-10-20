###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Assessment < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    available_filter_options do
      arg :assessment_name, [String]
      arg :project_type, [Types::HmisSchema::Enums::ProjectType]
      arg :project, [ID]
    end

    # object is a Hmis::Hud::CustomAssessment
    description 'Custom Assessment'
    field :id, ID, null: false
    field :lock_version, Integer, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: true
    field :client, HmisSchema::Client, null: false
    field :in_progress, Boolean, null: false
    access_field do
      can :edit_enrollments
      can :delete_enrollments
      can :delete_assessments
    end
    # Related records that were created by this Assessment, if applicable
    field :ce_assessment, Types::HmisSchema::CeAssessment, null: true
    field :event, Types::HmisSchema::Event, null: true
    field :income_benefit, Types::HmisSchema::IncomeBenefit, null: true
    field :health_and_dv, Types::HmisSchema::HealthAndDv, null: true
    field :exit, Types::HmisSchema::Exit, null: true
    field :disability_group, Types::HmisSchema::DisabilityGroup, null: true
    field :youth_education_status, Types::HmisSchema::YouthEducationStatus, null: true
    field :employment_education, Types::HmisSchema::EmploymentEducation, null: true
    custom_data_elements_field

    field :role, Types::Forms::Enums::AssessmentRole, null: false
    field :definition, Types::Forms::FormDefinition, null: false, description: 'Definition to use for viewing the assessment. If upgradedDefinitionForEditing is nil, then it should also be used for editing.'
    field :upgraded_definition_for_editing, Types::Forms::FormDefinition, null: true, description: 'Most recent published Definition to use for editing the assessment. Only present if the original form definition was retired.'
    field :wip_values, JsonObject, null: true

    def wip_values
      return unless object.in_progress?

      form_processor&.values
    end

    def role
      Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.invert[object.data_collection_stage]&.to_s
    end

    # EXPENSIVE! Do not use in batch
    def definition
      # If definition is stored on Form Processor, return that. This is the Definition that was most recently used to submit the Assessment.
      definition = load_ar_association(form_processor, :definition)
      # If there was no definition on the Form Processor, which would occur if this is a migrated HUD Assessment, then choose an appropriate one:
      definition ||= Hmis::Form::Definition.find_definition_for_role(role, project: project)
      # Apply filter context to filter out items that are not relevant for this project (HUD and Custom Rules)
      definition.filter_context = { project: project, active_date: object.assessment_date }
      definition
    end

    # EXPENSIVE! Do not use in batch
    def upgraded_definition_for_editing
      return if object.in_progress? # WIP assessments should use the original form for editing
      return unless form_processor.definition_id # tiny optimization: avoid calling 'definition' if it will invoke find_definition_for_role twice

      previous_definition = definition
      # If original form is not retired, then we should stil use it for editing.
      return unless previous_definition.retired?

      # Find the published version of the previous definition. If this resolves nil, then the original form will be used.
      published_definition = previous_definition.published_version
      published_definition&.filter_context = { project: project, active_date: object.assessment_date }
      published_definition
    end

    def in_progress
      object.in_progress?
    end

    def ce_assessment
      load_ar_association(form_processor, :ce_assessment)
    end

    def event
      load_ar_association(form_processor, :ce_event)
    end

    def income_benefit
      load_ar_association(form_processor, :income_benefit)
    end

    def health_and_dv
      load_ar_association(form_processor, :health_and_dv)
    end

    def exit
      load_ar_association(form_processor, :exit)
    end

    def disability_group
      return unless form_processor.present?

      # Load all the disability records
      disability_records = [
        :physical_disability,
        :developmental_disability,
        :chronic_health_condition,
        :hiv_aids,
        :mental_health_disorder,
        :substance_use_disorder,
      ].map { |d| load_ar_association(form_processor, d) }.compact
      return if disability_records.empty? && enrollment.disabling_condition.nil?

      # Build OpenStruct for DisabilityGroup type
      OpenStruct.new(
        id: object.id, # for logging
        information_date: object.assessment_date,
        data_collection_stage: object.data_collection_stage,
        enrollment: enrollment,
        user: user,
        disabilities: disability_records,
      )
    end

    def enrollment
      load_ar_association(object, :enrollment)
    end

    protected

    def form_processor
      fp = load_ar_association(object, :form_processor)
      # Each assessment should have a form processor. If it doesn't, it may point to an issue with
      # MigrateAssessmentsJob, SaveAssessment, SubmitAssessment, or a custom data migrations.
      raise "Assessment without form processor: #{object.id}" unless fp.present?

      fp
    end

    def project
      load_ar_association(object, :project)
    end
  end
end
