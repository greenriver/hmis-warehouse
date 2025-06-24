# frozen_string_literal: true

# resolve custom data elements (CDEs)
module Hmis::Ce::Match
  class CdeFieldMap
    def instance_value(client, field)
      cded = parse_entity_type(field)

      # choose the assessment that was most recently updated
      record = client.custom_assessments.joins(:definition).
        where(definition: { identifier: cded.form_definition_identifier }).
        order(:date_updated, :id).
        last
      return nil unless record

      # Get all CDE values for this definition
      cdes = record.custom_data_elements.where(data_element_definition: cded)
      return nil if cdes.empty?

      if cded.repeats
        # For multi-valued CDEs, return an array of values
        cdes.map { |cde| cded.read_value_from(cde) }.compact
      else
        # For single-valued CDEs, return the single value
        cded.read_value_from(cdes.first)
      end
    end

    # arel not supported.
    # Enhancement: if expression requires certain CDEs to be present then we could take a rough pass to filter out clients that lack the relevant assessments
    def arel_field(_field)
      nil
    end

    protected

    # custom_assessment.xyz
    def parse_entity_type(field)
      entity_type, cde_key = field.split('.', 2)

      klass = case entity_type
      when 'custom_assessment'
        Hmis::Hud::CustomAssessment
      # TBD: add support for CDEs on other entities such as Enrollments and Client
      else
        raise ArgumentError, "Unknown entity in field \"#{field}\""
      end

      cded = cded_lookup.dig(klass.sti_name, cde_key)
      raise ArgumentError, "Unknown CDE in field \"#{field}\"" unless cded

      cded
    end

    def cded_lookup
      # perhaps this should be constrained by data source
      @cded_lookup ||= Hmis::Hud::CustomDataElementDefinition.all.
        group_by(&:owner_type).
        transform_values { |definitions| definitions.index_by(&:key) }
    end
  end
end
