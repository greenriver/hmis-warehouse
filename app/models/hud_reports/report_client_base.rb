###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Base class for a report type's clients.
module HudReports
  class ReportClientBase < GrdaWarehouseBase
    self.abstract_class = true

    has_many :report_clients, as: :universe_membership, dependent: :destroy

    def display_value(col, pii_policy:, include_content_tag: true, cell_val: nil, calculate_cell: true)
      cell_val = fetch_cell_value(col) if calculate_cell

      return format_complex_value(col, cell_val, pii_policy, include_content_tag) if cell_val.is_a?(Array) || cell_val.is_a?(Hash)
      return format_boolean(cell_val, include_content_tag) if cell_val.in?([true, false])

      transform_value(col.to_s, cell_val, pii_policy)
    end

    private

    def fetch_cell_value(col)
      # We are expecting some columns to come through with a dot notation.
      # This will separate the object and method in order to call the appropriate column/method
      # while similarly allowing the method to be called if the column is not passed using dot notation.
      col.to_s.split('.').inject(self) do |obj, method|
        return unless obj

        if obj.respond_to?(:column_names) && obj.class.column_names.include?(method)
          obj[method]
        else
          obj.send(method)
        end
      end
    end

    def format_complex_value(col, value, pii_policy, include_content_tag)
      if value.is_a?(Array)
        # For Arrays, calculate each array element's value using the column name for the array
        value.map { |item| display_value(col, pii_policy: pii_policy, include_content_tag: include_content_tag, cell_val: item, calculate_cell: false) }
      elsif value.is_a?(Hash)
        # For Hashes, calculate each entry's value using each entry's key as the column name
        value.each do |k, v|
          value[k] = display_value(k.to_s, pii_policy: pii_policy, include_content_tag: include_content_tag, cell_val: v, calculate_cell: false)
        end
      end

      return ActionController::Base.helpers.content_tag(:pre, JSON.pretty_generate(value)) if include_content_tag

      value
    end

    def format_boolean(value, include_content_tag)
      Reports::ModelApplicationHelper.new.yes_no(value, include_content_tag: include_content_tag)
    end

    def transform_value(column, value, pii_policy)
      case column
      when /project_type$/
        HudUtility2024.project_type_brief(value)
      when /prior_living_situation$/
        HudUtility2024.living_situation(value)
      when /.*destination$/
        HudUtility2024.destination(value)
      when /_days_/
        number_with_delimiter(value)
      when /.*length_of_stay$/
        HudUtility2024.residence_prior_length_of_stay(value)
      when /^ssn$/
        GrdaWarehouse::PiiProvider.viewable_ssn(value, policy: pii_policy)
      when /^dob$/
        GrdaWarehouse::PiiProvider.viewable_dob(value, policy: pii_policy)
      when /ssn_quality$/
        HudUtility2024.ssn_data_quality(value)
      when /name_quality$/
        HudUtility2024.name_data_quality(value)
      when /dob_quality$/
        HudUtility2024.dob_data_quality(value)
      when /veteran_status$/
        HudUtility2024.veteran_status(value)
      when /relationship_to_hoh$/
        HudUtility2024.relationship_to_hoh(value)
      when /.*disabling_condition$/
        HudUtility2024.disability_response(value)
      when /.*first_name$/, /.*last_name$/, /.*middle_name$/, /.*full_name$/, /.*brief_name$/
        GrdaWarehouse::PiiProvider.viewable_name(value, policy: pii_policy)
      when /.*hiv_aids/
        GrdaWarehouse::PiiProvider.viewable_hiv_status(value, policy: pii_policy)
      else
        value
      end
    end
  end
end
