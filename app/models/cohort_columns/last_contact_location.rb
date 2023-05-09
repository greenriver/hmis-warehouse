###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastContactLocation < ReadOnly
    attribute :column, String, lazy: true, default: :last_intentional_contact_location
    attribute :translation_key, String, lazy: true, default: 'Last Intentional Contacts'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Locations of the most recent client contact'
    end

    def display_read_only(user)
      value(cohort_client, user)
    end

    def value_requires_user?
      true
    end

    def value(cohort_client, user) # OK
      contacts = cohort_client.client.last_intentional_contacts(user, include_dates: true)
      return unless contacts.present?

      contacts.join('; ')
    end
  end
end
