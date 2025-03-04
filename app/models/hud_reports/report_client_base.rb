# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Base class for a report type's clients.
module HudReports
  class ReportClientBase < GrdaWarehouseBase
    include ActionView::Helpers
    include ActionView::Context
    include ApplicationHelper
    self.abstract_class = true

    has_many :report_clients, as: :universe_membership, dependent: :destroy

    def display_value(col, pii_policy:, include_content_tag: true)
      # We are expecting some columns to com through with a dot notation.
      # This will separate the object and method in order to call the appropriate column/method
      # while similarly allowing the method to be called if the column is not passed using dot notation.
      cell = col.to_s.split('.').inject(self) do |obj, method|
        value = obj[method]
        value = obj.send(method) if value.nil?
        value
      end

      return ActionController::Base.helpers.content_tag(:pre, JSON.pretty_generate(cell)) if include_content_tag && (cell.is_a?(Array) || cell.is_a?(Hash))
      return yes_no(cell, include_content_tag: include_content_tag) if cell.in?([true, false])

      case col.to_s
      when /project_type$/
        HudUtility2024.project_type_brief(cell)
      when /prior_living_situation$/
        HudUtility2024.living_situation(cell)
      when /.*destination$/
        HudUtility2024.destination(cell)
      when /_days_/
        number_with_delimiter(cell)
      when /.*length_of_stay$/
        HudUtility2024.residence_prior_length_of_stay(cell)
      when /^ssn$/
        masked_ssn(cell, include_content_tag: include_content_tag)
      when /^dob$/
        GrdaWarehouse::PiiProvider.viewable_dob(cell, policy: pii_policy)
      when /ssn_quality$/
        HudUtility2024.ssn_data_quality(cell)
      when /name_quality$/
        HudUtility2024.name_data_quality(cell)
      when /dob_quality$/
        HudUtility2024.dob_data_quality(cell)
      when /veteran_status$/
        HudUtility2024.veteran_status(cell)
      when /relationship_to_hoh$/
        HudUtility2024.relationship_to_hoh(cell)
      when /.*disabling_condition$/
        HudUtility2024.disability_response(cell)
      when 'first_name', 'last_name', 'middle_name', 'full_name', 'brief_name'
        GrdaWarehouse::PiiProvider.viewable_name(cell, policy: pii_policy)
      else
        cell
      end
    end
  end
end
