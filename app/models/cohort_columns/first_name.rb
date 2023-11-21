###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class FirstName < ReadOnly
    attribute :column, String, lazy: true, default: :first_name
    attribute :translation_key, String, lazy: true, default: 'First Name'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'First name of the client'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def column_editable?
      false
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      cohort_client.client.FirstName
    end

    def display_for(user)
      display_read_only(user)
    end

    def display_read_only(user)
      html = content_tag(:span, class: 'hidden') do
        value(cohort_client)
      end
      html += link_to_if(user.can_access_some_version_of_clients?, value(cohort_client), appropriate_client_path(cohort_client.client), target: '_blank')
      html
    end
  end
end
