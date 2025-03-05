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

    self.abstract_class = true

    has_many :report_clients, as: :universe_membership, dependent: :destroy

    def display_value(col, pii_policy:, include_content_tag: true)
      # We are expecting some columns to com through with a dot notation.
      # This will separate the object and method in order to call the appropriate column/method
      # while similarly allowing the method to be called if the column is not passed using dot notation.
      cell = col.to_s.split('.').inject(self) do |obj, method|
        if obj.class.column_names.include?(method)
          obj[method]
        else
          obj.send(method)
        end
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

    # Including Applicaiton Helper had name clashes with classes inheriting from this base class.
    # Including this method here as a work around.
    def yes_no(boolean, include_icon: true, include_content_tag: true)
      return 'Not Specified' if boolean.nil?

      case boolean
      when true, 'Yes'
        if include_content_tag
          capture do
            concat content_tag :span, nil, class: 'icon-checkmark o-color--positive' if include_icon
            concat ' Yes'
          end
        else
          'Yes'
        end
      when false, 'No'
        if include_content_tag
          capture do
            concat content_tag :span, nil, class: 'icon-cross o-color--danger' if include_icon
            concat ' No'
          end
        else
          'No'
        end
      when 'Refused'
        if include_content_tag
          capture do
            concat content_tag :span, nil, class: 'icon-warning o-color--warning' if include_icon
            concat ' Refused/Unsure'
          end
        else
          'Refused/Unsure'
        end
      end
    end

    # Including Applicaiton Helper had name clashes with classes inheriting from this base class.
    # Including this method here as a work around.
    def masked_ssn(number, include_content_tag: true)
      # pad with leading 0s if we don't have enough characters
      number = number.to_s.rjust(9, '0') if number.present?
      value = number.to_s.gsub(HudUtility2024::SSN_RGX, 'XXX-XX-\3')
      return value unless include_content_tag

      ActionController::Base.helpers.content_tag :span, number.to_s.gsub(HudUtility2024::SSN_RGX, 'XXX-XX-\3')
    end
  end
end
