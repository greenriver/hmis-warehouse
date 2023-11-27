###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OpenEnrollments < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :open_enrollments
    attribute :translation_key, String, lazy: true, default: 'Open Residential Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'List of project types for which the client has an open enrollment in SO, ES, SH, TH, or PH'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def column_editable?
      false
    end

    def default_input_type
      :enrollment_tag
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.open_enrollments
    end

    def text_value(cohort_client)
      v = value(cohort_client)
      return '' unless v.present?

      v&.map(&:last)&.join(' ')
    end

    def display_for(user)
      display_read_only(user)
    end

    def display_read_only(_user)
      open_enrollments = value(cohort_client)
      return unless open_enrollments

      open_enrollments.map do |project_type, text|
        content_tag(:div, class: "enrollment__project_type client__service_type_#{project_type}") do
          content_tag(:em, class: 'service-type__program-type') do
            text
          end
        end
      end.join(' ').html_safe
    end
  end
end
