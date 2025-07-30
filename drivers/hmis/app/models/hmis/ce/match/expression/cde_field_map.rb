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
    def clients_query(clients, field)
      cded = parse_entity_type(field)
      cde_scope = Hmis::Hud::CustomDataElement.where(data_element_definition: cded)

      # choose the assessment that was most recently updated
      cde_values = Hmis::Hud::CustomAssessment.joins(client: :warehouse_client_source).
        where(warehouse_clients: { destination_id: clients.select(:id) }).
        joins(:definition).
        where(definition: { identifier: cded.form_definition_identifier }).
        joins(:custom_data_elements).merge(cde_scope)
        order(:date_updated, :id).
        select(
          arel.wc_t[Arel.star].distinct_on(arel.wc_t[:destination_id]),
          cde_t[cded.cde_arel_field],
        )

      if cded.repeats?
        cde_values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
      else
        cde_values.index_by(&:first).transform_values { |row| row.last }
      end
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

    # Value for user-facing display of resolved field
    def instance_value_for_display(client, field)
      value = instance_value(client, field)
      Array.wrap(value).map do |v|
        if v.is_a?(TrueClass)
          'Yes'
        elsif v.is_a?(FalseClass)
          'No'
        elsif v.is_a?(Date)
          v.strftime('%m/%d/%Y')
        else
          v.to_s
        end
      end
    end

    # arel not supported.
    # Enhancement: if expression requires certain CDEs to be present then we could take a rough pass to filter out clients that lack the relevant assessments
    def arel_field(_field)
      nil
    end

    def joins(_field)
      nil
    end

    protected

    # client is a destination client
    def custom_assessment_cdes(cded, client)
      # choose the assessment that was most recently updated
      record = Hmis::Hud::CustomAssessment.joins(client: :warehouse_client_source).
        where(warehouse_clients: { destination_id: client.id }).
        joins(:definition).
        where(definition: { identifier: cded.form_definition_identifier }).
        order(:date_updated, :id).
        last
      return [] unless record

      record.custom_data_elements.where(data_element_definition: cded).to_a
    end

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
