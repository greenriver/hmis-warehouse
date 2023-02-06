###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DisabilityGroup < Types::BaseObject
    description 'Group of disability records that were collected at the same time'

    field :id, ID, 'Concatenated string of Disability record IDs', null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :user, HmisSchema::User, null: true
    field :information_date, GraphQL::Types::ISO8601Date, null: false
    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false
    field :disabling_condition, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, 'Current disabling condition on the linked Enrollment. It may not match up with the disabilities specified in this group.', null: false

    # Disability Type 5
    field :physical_disability, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :physical_disability_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 6
    field :developmental_disability, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 7
    field :chronic_health_condition, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :chronic_health_condition_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 8
    field :hiv_aids, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    # ADD t_cell_count_available
    # ADD t_cell_count
    # ADD t_cell_source
    # ADD viral_load_available
    # ADD viral_load
    # ADD anti_retroviral

    # Disability Type 9
    field :mental_health_disorder, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :mental_health_disorder_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 10
    field :substance_use_disorder, HmisSchema::Enums::Hud::DisabilityResponse, null: true
    field :substance_use_disorder_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    field :date_created, GraphQL::Types::ISO8601DateTime, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true

    def id
      # Concatenate disability IDs to create a unique id for the group
      object.disabilities.map(&:id).join(':')
    end

    def date_created
      object.disabilities.map(&:date_created).map(&:to_datetime).max
    end

    def date_updated
      object.disabilities.map(&:date_updated).map(&:to_datetime).max
    end

    def disabling_condition
      object.enrollment.disabling_condition || 99
    end

    def physical_disability
      response_for_type(5)
    end

    def physical_disability_indefinite_and_impairs
      indefinite_and_impairs_for_type(5)
    end

    def developmental_disability
      response_for_type(6)
    end

    def chronic_health_condition
      response_for_type(7)
    end

    def chronic_health_condition_indefinite_and_impairs
      indefinite_and_impairs_for_type(7)
    end

    def hiv_aids
      response_for_type(8)
    end

    def mental_health_disorder
      response_for_type(9)
    end

    def mental_health_disorder_indefinite_and_impairs
      indefinite_and_impairs_for_type(9)
    end

    def substance_use_disorder
      response_for_type(10)
    end

    def substance_use_disorder_indefinite_and_impairs
      indefinite_and_impairs_for_type(10)
    end

    private def response_for_type(disability_type)
      object.disabilities.find { |r| r.disability_type == disability_type }&.disability_response
    end

    private def indefinite_and_impairs_for_type(disability_type)
      object.disabilities.find { |r| r.disability_type == disability_type }&.indefinite_and_impairs
    end
  end
end
