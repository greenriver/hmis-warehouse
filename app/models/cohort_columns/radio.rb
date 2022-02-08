###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Radio < Base
    def default_input_type
      :radio_buttons
    end

    def available_options
      { true => 'yes', false => 'no' }
    end

    def display_for(user)
      value = value(cohort_client)
      if display_as_editable?(user, cohort_client)
        content_tag(:div, class: 'form-group cohort-client__input') do
          available_options.map do |k, v|
            selected = if k == true
              !!value
            elsif k == false
              !value
            else
              v == value
            end

            concat(content_tag(:div) do
              label_tag("#{form_group}_#{column}_#{k}", class: :radio) do
                concat(radio_button(form_group, column, k, checked: selected, class: input_class))
                concat(v)
              end
            end)
          end
        end
      else
        display_read_only(user)
      end
    end

    def display_read_only(_user)
      available_options[value(cohort_client)]
    end
  end
end
