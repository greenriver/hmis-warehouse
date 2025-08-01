# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for CDE fields
  class CdeFieldMap
    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    # Possible reasons why this could this return nil:
    # * the question was left empty on the form
    # * the question was disabled by conditional logic on the form
    # * the version of the form definition did not include the question at the time the form was submitted
    def client_query(clients, field)
      cded = parse_entity_type(field)

      client_ids = clients.pluck(:id)
      cde_t = Hmis::Hud::CustomDataElement.arel_table
      values = Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: client_ids).
        where(form_identifier: cded.form_definition_identifier).
        joins(custom_assessment: :custom_data_elements).
        where(cde_t[:data_element_definition_id].eq(cded.id)).
        pluck(
          :destination_client_id,
          cded.cde_arel_field,
        )

      if cded.repeats?
        result = values.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
        default_value = []
      else
        result = values.to_h
        default_value = nil
      end

      # Ensure all clients are in the hash, setting a default value for those missing.
      client_ids.each do |client_id|
        result[client_id] ||= default_value
      end

      result
    end

    def joins(_field)
      # CDE fields don't require additional joins since they're handled via direct queries
      nil
    end

    def arel_field(_field)
      # CDE fields are resolved via queries, not direct arel fields
      nil
    end

    def cdeds_for(fields)
      fields.map do |field|
        parse_entity_type(field)
      end.uniq
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      parse_entity_type(field)&.label
    end

    def format_for_display(field, value)
      cded = parse_entity_type(field)
      return _format_for_display(field, value) unless cded.repeats?

      Array.wrap(value).map { |v| _format_for_display(field, v) }
    end

    private

    def _format_for_display(field, value)
      cded = parse_entity_type(field)
      case cded.field_type.to_sym
      when :boolean
        return 'Yes' if value == true
        return 'No' if value == false
      when :date
        value&.strftime('%m/%d/%Y')
      when :string, :text
        value&.to_s
      when :integer, :float
        value
      end
    end

    def arel
      Hmis::ArelHelper.instance
    end

    protected

    # parses a key of the format 'custom_assessment.xyz'
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

    # supports lookup by owner_type and field_name
    # {'Hmis::Hud::CustomAssessment' => {'language' => cded}}
    def cded_lookup
      @cded_lookup ||= Hmis::Hud::CustomDataElementDefinition.all.
        group_by(&:owner_type).
        transform_values { |definitions| definitions.index_by(&:key) }
    end
  end
end
