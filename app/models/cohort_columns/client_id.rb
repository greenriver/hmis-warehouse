###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ClientId < ReadOnly
    attribute :column, String, lazy: true, default: :client_id
    attribute :translation_key, String, lazy: true, default: 'Client ID'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client)
      cohort_client.client_id
    end

    def display_read_only(user)
      html = content_tag(:span, value(cohort_client), class: 'hidden')
      html += link_to_if(user.can_access_some_version_of_clients?, value(cohort_client), appropriate_client_path(cohort_client.client), target: '_blank')
      html
    end
  end
end
