###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

    def transform_value(key, value, pii_policy)
      case key
      when /.*first_name$/, /.*last_name$/, /.*middle_name$/, /.*full_name$/, /.*brief_name$/
        GrdaWarehouse::PiiProvider.viewable_name(value, policy: pii_policy)
      when /^dob$/
        GrdaWarehouse::PiiProvider.viewable_dob(value, policy: pii_policy)
      when /^ssn$/
        GrdaWarehouse::PiiProvider.viewable_ssn(value, policy: pii_policy)
      when /.*hiv_aids/
        GrdaWarehouse::PiiProvider.viewable_hiv_status(value, policy: pii_policy)
      else
        value
      end
    end

    def download_value(key, pii_policy:)
      translator = self.class.detail_headers[key][:translator]
      value = transform_value(key, public_send(key), pii_policy)
      return translator.call(value) if translator.present?
      return value == true ? 'Yes' : 'No' if value.in?([true, false])

      value
    end

    # Returns the project_id to use for PII policy checks
    # For items with multiple projects (like Client), finds the first one the user has access to
    # Falls back to the first project_id if none are accessible
    def project_id_for_policy(viewable_project_ids:)
      if respond_to?(:project_ids) && project_ids.present?
        project_ids.find { |pid| viewable_project_ids.include?(pid) } || project_ids.first
      else
        project_id
      end
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
