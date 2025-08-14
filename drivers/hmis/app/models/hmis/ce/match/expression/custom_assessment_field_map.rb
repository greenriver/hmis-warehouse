# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  class CustomAssessmentFieldMap
    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      form_definition, field_name = parse_entity_type(field)
      callback = all.dig(field_name, :query)
      callback.call(clients)
    end

    def client_query(clients, field)
      form_definition, field_name = parse_entity_type(field)

      client_ids = clients.pluck(:id)
      cde_t = Hmis::Hud::CustomDataElement.arel_table
      result = Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: client_ids).
        where(form_identifier: form_definition_identifier).
        joins(:custom_assessment).
        pluck(:destination_client_id, attribute).
        to_h

      # Ensure all clients are in the hash, setting a default value for those missing.
      client_ids.each do |client_id|
        # we might need to support booleans in the future
        result[client_id] = nil unless result.key?(client_id)
      end

      result
    end

    def joins(field)
      # not yet implemented
      nil
    end

    def arel_field(_field)
      # not yet implemented
      nil
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      formatted = all.dig(field.to_sym, :label)
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = all.dig(field.to_sym, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    protected

    def arel
      Hmis::ArelHelper
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
        query: ->(clients) { assessments.pluck(:id, :AssessmentDate).to_h },
        format_for_display: method(:format_date)
        label: 'Date Assessment Administered',
      }
    end

    def date_created_field
      {
        query: ->(clients) { assessments.pluck(:id, :DateCreated).to_h },
        format_for_display: method(:format_date)
        label: 'Date Assessment Created',
      }
    end

    def date_updated_field
      {
        query: ->(clients) { assessments.pluck(:id, :DateUpdated).to_h },
        format_for_display: method(:format_date)
        label: 'Date Assessment Last Updated',
      }
    end

    # custom_assessment.<identifier>.<metadata field>
    # field format: 'custom_assessment.housing_assessment.date_updated'
    def parse_entity_type(field)
      form_identifier, field_name = field.split('.', 2)
      field_name = field_name&.to_sym

      raise ArgumentError, "Unknown form identifier \"#{field}\"" unless form_identifier.in?(valid_form_identifiers)
      raise ArgumentError, "Unknown field \"#{field}\"" unless field_name.in?(all)

      [form_identifier, field_name]
    end

    def valid_form_identifiers
      @valid_form_identifiers ||= Hmis::Form::Definition.distinct.pluck(:identifier).to_set
    end

    def format_date(date)
      value&.strftime('%m/%d/%Y')
    end
  end
end
