# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  class CustomAssessmentFieldMap
    include Memery

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      form_definition_identifier, field_name = parse_entity_type(field)
      column = column_for_field(field_name)
      client_ids = clients.pluck(:id)

      result = Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: client_ids).
        where(form_identifier: form_definition_identifier).
        joins(:custom_assessment).
        pluck(:destination_client_id, column).
        to_h

      # Ensure all clients are in the hash, setting a default value for those missing.
      client_ids.each do |client_id|
        # we might need to support booleans in the future
        result[client_id] = nil unless result.key?(client_id)
      end

      result
    end

    def joins(_field)
      # Join latest-assessment view and the associated custom assessment
      [{ destination_client_latest_assessments: :custom_assessment }]
    end

    def arel_field(field)
      form_definition_identifier, field_name = parse_entity_type(field)
      ca_column = column_for_field(field_name)
      dcla_t = Hmis::DestinationClientLatestAssessment.arel_table

      # Gate the column by matching form identifier to avoid cross-form bleed when joined
      arel.acase([[dcla_t[:form_identifier].eq(form_definition_identifier), ca_column]], elsewise: nil)
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      _, field_name = parse_entity_type(field)
      all.dig(field_name, :label)
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      _, field_name = parse_entity_type(field)
      formatted = all.dig(field_name, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    protected

    def arel
      Hmis::ArelHelper.instance
    end

    def all
      @all ||= {
        assessment_date: assessment_date_field,
        date_created: date_created_field,
        date_updated: date_updated_field,
      }
    end

    def assessment_date_field
      {
        format_for_display: method(:format_date),
        label: 'Date Assessment Administered',
      }
    end

    def date_created_field
      {
        format_for_display: method(:format_date),
        label: 'Date Assessment Created',
      }
    end

    def date_updated_field
      {
        format_for_display: method(:format_date),
        label: 'Date Assessment Last Updated',
      }
    end

    # field format: '<form_identifier>.<metadata_field>'
    # example: 'housing_assessment.date_updated'
    memoize def parse_entity_type(field)
      form_identifier, field_name = field.split('.', 2)
      field_name = field_name&.to_sym

      raise ArgumentError, "Unknown form identifier \"#{form_identifier}\"" unless form_identifier.in?(valid_form_identifiers)
      raise ArgumentError, "Unknown field \"#{field_name}\"" unless field_name.in?(all.keys)

      [form_identifier, field_name]
    end

    def valid_form_identifiers
      @valid_form_identifiers ||= Hmis::Form::Definition.distinct.pluck(:identifier).to_set
    end

    def format_date(value)
      value&.strftime('%m/%d/%Y')
    end

    def column_for_field(field_name)
      case field_name
      when :assessment_date
        arel.cas_t[:AssessmentDate]
      when :date_created
        arel.cas_t[:DateCreated]
      when :date_updated
        arel.cas_t[:DateUpdated]
      else
        raise ArgumentError, "Unknown field: #{field_name}"
      end
    end
  end
end
