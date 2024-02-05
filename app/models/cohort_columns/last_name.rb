###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastName < ReadOnly
    attribute :column, String, lazy: true, default: :last_name
    attribute :translation_key, String, lazy: true, default: 'Last Name'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Last name of the client'
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
      cohort_client.client.LastName
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
