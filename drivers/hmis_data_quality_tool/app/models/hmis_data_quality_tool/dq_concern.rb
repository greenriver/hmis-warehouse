###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::DqConcern
  extend ActiveSupport::Concern
  included do
    def self.import_intermediate!(values)
      import!(
        values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: attribute_names.map(&:to_sym),
        },
      )
    end

    def self.section_title(slug, report)
      sections(report)[slug].try(:[], :title)
    end

    def self.section_description(slug, report)
      sections(report)[slug].try(:[], :description)
    end

    def self.required_for(slug, report)
      sections(report)[slug].try(:[], :required_for)
    end

    def self.calculate_issues(report_items, report)
      calculate(report_items: report_items, report: report)
    end

    def self.detail_headers_for(slug, report, export:)
      section = sections(report)[slug.to_sym]

      header_source = if export
        detail_headers_for_export
      else
        detail_headers
      end
      headers = header_source.transform_values { |v| v.except(:translator) }
      return headers unless section

      columns = section[:detail_columns]
      return headers unless columns.present?

      headers.select { |k, _| k.in?(columns) }
    end

    def download_value(key)
      translator = self.class.detail_headers[key][:translator]
      value = public_send(key)
      return translator.call(value) if translator.present?
      return value == true ? 'Yes' : 'No' if value.in?([true, false])

      value
    end

    # returns [stay_length_category, stay_length_limit]
    def self.stay_length_limit(key, report)
      section = sections(report)[key]
      # To maintain compatibility with the API
      values = [nil, nil]
      return values unless section.present?

      limits = HmisDataQualityTool::Goal.stay_length_categories.map do |stay_length_category|
        [stay_length_category, section[stay_length_category]] if section[stay_length_category].present?
      end.compact
      return values unless limits.present?

      limits.first
    end
  end
end
