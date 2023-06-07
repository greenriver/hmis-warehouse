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
    end

    description 'Custom Assessment'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    field :custom_form, HmisSchema::CustomForm, null: true
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
    custom_data_elements_field

    def in_progress
      object.in_progress?
    end

    def income_benefit
      object.custom_form&.form_processor&.income_benefit
    end

    def health_and_dv
      object.custom_form&.form_processor&.health_and_dv
    end

    def exit
      object.custom_form&.form_processor&.exit
    end

    def disability_group
      form_processor = object.custom_form&.form_processor
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

    def custom_form
      load_ar_association(object, :custom_form)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
