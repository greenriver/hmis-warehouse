###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern to provide standardized history change descriptions
module HistoryDescriptions
  extend ActiveSupport::Concern

  class_methods do
    def describe_changes(version, changes, excluded_fields = [])
      model_name_string = model_name.to_s.underscore.humanize.downcase
      case version.event
      when 'create'
        ["Created #{model_name_string}"]
      when 'update'
        # Filter out excluded fields
        filtered_changes = changes.reject { |field, _| excluded_fields.include?(field.to_s) }

        if filtered_changes.empty?
          ["Modified #{model_name_string}"]
        else
          filtered_changes.map do |field, values|
            from, to = values
            "Changed #{field.humanize.titleize}: from #{render_changed_value(field, from)} to #{render_changed_value(field, to)}"
          end
        end
      when 'destroy'
        ["Deleted #{model_name_string}"]
      else
        ["Modified #{model_name_string}"]
      end
    end

    def render_changed_value(_field, value)
      return 'nil' if value.nil?
      return 'true' if value == true
      return 'false' if value == false
      return value.to_s if value.is_a?(Numeric)
      return value.to_s if value.is_a?(String)

      value.to_s
    end
  end
end
