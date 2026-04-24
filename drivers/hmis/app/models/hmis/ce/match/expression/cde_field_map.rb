# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for CDE fields
  class CdeFieldMap
    include Memery

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
        next if result.key?(client_id)

        result[client_id] = default_value
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

    # Builds a correlated `EXISTS` SQL fragment (and bind values) for narrowing CE Client scopes.
    #
    # Added to support dynamic filtering on CE waitlists based on CDE values, using
    # `cde.*` keys from `Hmis::Filter::CeClientFilter` / table configuration.
    #
    # The subquery is correlated to `ce_client_proxies.client_id` (destination warehouse client id).
    # Like {#client_query}, matching uses `Hmis::DestinationClientLatestAssessment` so only the
    # latest assessment row per form (for that destination client) is considered.
    #
    # Values are compared as `column::text IN (...)` so HUD/UI string filter values behave predictably.
    # `filter_values` must be non-empty after stripping blanks; callers with nothing to match should skip.
    #
    # @param custom_assessment_field [String] CDE path in the shape accepted by {#parse_entity_type}
    #   (e.g. `'custom_assessment.primary_language'`, the portion of a `cde.*` expression key after `cde.`)
    # @param filter_values [Array<String,#to_s>] String values to match against  (e.g. ['English', 'Spanish'])
    # @return [Array(String, Array)] SQL string and bind arguments for `scope.where([sql, *binds])`
    def self.sql_cde_value_exists_for_ce_client_proxy(custom_assessment_field, filter_values)
      filter_values = Array.wrap(filter_values).map(&:to_s).reject(&:blank?).uniq
      raise ArgumentError, 'filter_values must be non-empty' if filter_values.empty?

      conn = ActiveRecord::Base.connection
      dcla = conn.quote_table_name(Hmis::DestinationClientLatestAssessment.table_name)
      ca = conn.quote_table_name(Hmis::Hud::CustomAssessment.table_name)
      cde_tbl = conn.quote_table_name(Hmis::Hud::CustomDataElement.table_name)
      cde_alias = 'cde'
      proxy = conn.quote_table_name(Hmis::Ce::ClientProxy.table_name)

      # Get the CustomDataElementDefinition and determine the value column name (e.g. value_string)
      cded = new.send(:parse_entity_type, custom_assessment_field)
      value_col = conn.quote_column_name(cded.cde_arel_field.name.to_s)

      # Create predicate for matching CustomDataElement values
      # For example: (cde.value_string)::text IN (?, ?, ?)
      placeholders = filter_values.map { '?' }.join(', ')
      value_predicate = "(#{cde_alias}.#{value_col})::text IN (#{placeholders})"

      sql = <<~SQL
        EXISTS (
          SELECT 1
          FROM #{dcla} dcla
          INNER JOIN #{ca} ca ON ca.id = dcla.custom_assessment_id AND ca."DateDeleted" IS NULL
          INNER JOIN #{cde_tbl} #{cde_alias} ON #{cde_alias}.owner_type = ?
            AND #{cde_alias}.owner_id = ca.id
            AND #{cde_alias}."DateDeleted" IS NULL
            AND #{cde_alias}.data_element_definition_id = ?
          WHERE dcla.destination_client_id = #{proxy}.client_id
            AND dcla.form_identifier = ?
            AND (#{value_predicate})
        )
      SQL

      # Values to bind to the '?' placeholders in the SQL fragment
      binds = [Hmis::Hud::CustomAssessment.name, cded.id, cded.form_definition_identifier] + filter_values
      [sql.squish, binds]
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

    # parses a key of the format 'custom_assessment.xyz'
    memoize def parse_entity_type(field)
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
