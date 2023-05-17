###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class DisabilityGroupProcessor < Base
    def process(field, value)
      disability_type, disability_field, enum_type = field_mapping[field]
      return unless disability_type.present?

      disability_value = attribute_value_for_enum(enum_type, value)
      @processor.send(disability_type).assign_attributes(disability_field => disability_value)
    end

    def information_date(date)
      factory_names = field_mapping.values.map(&:first) - [:enrollment_factory] # Enrollments don't have information dates
      factory_names.each do |factory_name|
        @processor.send(factory_name, create: false)&.assign_attributes(information_date: date)
      end
    end

    def assign_metadata
      factory_names = field_mapping.values.map(&:first)
      factory_names.each do |factory_name|
        @processor.send(factory_name, create: false)&.assign_attributes(
          user: @processor.hud_user,
          data_source_id: @processor.hud_user.data_source_id,
        )
      end
    end

    def field_mapping
      @field_mapping ||= begin
        standard_enum = Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
        {
          'disablingCondition' => [:enrollment_factory, :disabling_condition, standard_enum],

          'physicalDisability' => [:physical_disability_factory, :disability_response, standard_enum],
          'physicalDisabilityIndefiniteAndImpairs' => [:physical_disability_factory, :indefinite_and_impairs, standard_enum],

          'developmentalDisability' => [:developmental_disability_factory, :disability_response, standard_enum],

          'chronicHealthCondition' => [:chronic_health_condition_factory, :disability_response, standard_enum],
          'chronicHealthConditionIndefiniteAndImpairs' => [:chronic_health_condition_factory, :indefinite_and_impairs, standard_enum],

          'hivAids' => [:hiv_aids_factory, :disability_response, standard_enum],

          'mentalHealthDisorder' => [:mental_health_disorder_factory, :disability_response, standard_enum],
          'mentalHealthDisorderIndefiniteAndImpairs' => [:mental_health_disorder_factory, :indefinite_and_impairs, standard_enum],

          'substanceUseDisorder' => [:substance_use_disorder_factory, :disability_response, Types::HmisSchema::Enums::Hud::DisabilityResponse],
          'substanceUseDisorderIndefiniteAndImpairs' => [:substance_use_disorder_factory, :indefinite_and_impairs, standard_enum],
        }.freeze
      end
    end
  end
end
