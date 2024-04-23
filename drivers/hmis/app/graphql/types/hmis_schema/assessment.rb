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
      arg :type, [String]
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

      form_processor = load_ar_association(object, :form_processor)
      # If this occurs, it may be an issue with MigrateAssessmentsJob, SaveAssessment, or SubmitAssessment
      raise "Assessment without form processor: #{object.id}" unless form_processor.present?

      # If definition is stored on form processor, return that.
      # TODO: check if form is retired? For non-WIP non-custom assessments, we should
      # really be choosing the "latest" form, which may not be the one on the FormProcessor.
      definition = load_ar_association(form_processor, :definition)
      # If there was no definition specified, which would occur if this is a migrated assessment, choose an appropriate one.
      definition ||= Hmis::Form::Definition.find_definition_for_role(role, project: project)
      definition.filter_context = { project: project, active_date: object.assessment_date }
      definition
    end

    def in_progress
      object.in_progress?
    end

    def ce_assessment
      form_processor ? load_ar_association(form_processor, :ce_assessment) : nil
    end

    def event
      form_processor ? load_ar_association(form_processor, :ce_event) : nil
    end

    def income_benefit
      form_processor ? load_ar_association(form_processor, :income_benefit) : nil
    end

    def health_and_dv
      form_processor ? load_ar_association(form_processor, :health_and_dv) : nil
    end

    def exit
      form_processor ? load_ar_association(form_processor, :exit) : nil
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
      load_ar_association(object, :form_processor)
    end
  end
end
