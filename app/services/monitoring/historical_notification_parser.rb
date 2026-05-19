###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Monitoring
  class HistoricalNotificationParser
    def self.parse(message)
      new(message).parse
    end

    def initialize(message)
      @message = message
    end

    def parse
      return {} unless @message.html?

      doc = Nokogiri::HTML(@message.body)
      subject = @message.subject
      if subject.include?(GrdaWarehouse::Monitoring::ThresholdNotificationLog::METRIC_THRESHOLD_SUBJECT)
        parse_metric_threshold(doc)
      elsif subject.include?(GrdaWarehouse::Monitoring::ThresholdNotificationLog::IMPORT_PROCESSING_SUBJECT)
        parse_import_processing(doc)
      else
        {}
      end
    rescue StandardError
      {}
    end

    private

    def parse_metric_threshold(doc)
      crossings = doc.css('h3').filter_map do |h3|
        metric_name = h3.text.strip
        link = h3.next_element&.css('a')&.find { |a| a.text.strip == 'View metric details' }
        next unless link

        href = link['href']
        metric_id = href&.match(/\/metric_definitions\/(\d+)/)&.captures&.first&.to_i
        next unless metric_id&.positive?

        config_path = begin
          URI.parse(href).path
        rescue URI::InvalidURIError
          href
        end

        {
          'metric_id' => metric_id,
          'metric_name' => metric_name,
          'config_label' => metric_name,
          'config_url' => config_path,
        }
      end

      { 'crossings' => crossings }
    end

    def parse_import_processing(doc)
      text = doc.text
      data_source_name = text.match(/An import in the (.+?) data source/)&.captures&.first
      import_href = doc.css('a').map { |a| a['href'] }.find { |u| u&.match?(/\/imports\/\d+/) }
      import_log_id = import_href&.match(/\/imports\/(\d+)/)&.captures&.first&.to_i
      config_path = begin
        URI.parse(import_href).path if import_href
      rescue URI::InvalidURIError
        import_href
      end

      {
        'data_source_name' => data_source_name,
        'error_threshold_met' => text.include?('error count threshold'),
        'count_threshold_met' => text.include?('record count change threshold'),
        'paused' => text.include?('The import is paused'),
        'import_log_id' => import_log_id,
        'config_url' => config_path,
      }
    end
  end
end
