###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::DisabilityGroup < Types::BaseObject
    description 'Group of disability records that were collected at the same time'

    field :id, ID, 'Concatenated string of Disability record IDs', null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :user, Application::User, null: true
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
    field :t_cell_count_available, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :t_cell_count, Integer, null: true
    field :t_cell_source, HmisSchema::Enums::Hud::TCellSourceViralLoadSource, null: true
    field :viral_load_available, HmisSchema::Enums::Hud::ViralLoadAvailable, null: true
    field :viral_load, Integer, null: true
    field :viral_load_source, HmisSchema::Enums::Hud::TCellSourceViralLoadSource, null: true
    field :anti_retroviral, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 9
    field :mental_health_disorder, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :mental_health_disorder_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    # Disability Type 10
    field :substance_use_disorder, HmisSchema::Enums::Hud::DisabilityResponse, null: true
    field :substance_use_disorder_indefinite_and_impairs, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    field :date_created, GraphQL::Types::ISO8601DateTime, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true

    # Object is an OpenStruct containing all Disability records from a given Assessment

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

    [
      :t_cell_count_available,
      :t_cell_count,
      :t_cell_source,
      :viral_load_available,
      :viral_load,
      :viral_load_source,
      :anti_retroviral,
    ].each do |field|
      define_method(field) do
        object.disabilities.find { |r| r.disability_type == 8 }&.send(field)
      end
    end

    private def response_for_type(disability_type)
      object.disabilities.find { |r| r.disability_type == disability_type }&.disability_response
    end

    private def indefinite_and_impairs_for_type(disability_type)
      object.disabilities.find { |r| r.disability_type == disability_type }&.indefinite_and_impairs
    end
  end
end
