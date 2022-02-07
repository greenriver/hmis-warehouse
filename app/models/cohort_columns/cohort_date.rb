###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CohortDate < Base
    def default_input_type
      :date_picker
    end

    def date_format
      'll'
    end

    def display_for(user)
      if display_as_editable?(user, cohort_client)
        content_tag(:div, class: 'input-group date', data: { provide: :datepicker }) do
          content_tag(:div, class: 'form-group') do
            text_field(form_group, column, value: value(cohort_client), size: 10, style: 'width: 8em;', type: :text, class: ['form-control', input_class])
          end +
          content_tag(:span, '', class: 'input-group-addon icon-calendar')
        end
      else
        display_read_only(user)
      end
    end

    def renderer
      'date'
    end

    def display_read_only(_user)
      value(cohort_client)&.to_date&.to_s rescue value(cohort_client).to_s
    end
  end
end
