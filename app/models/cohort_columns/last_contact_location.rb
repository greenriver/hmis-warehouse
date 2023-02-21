###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastContactLocation < ReadOnly
    attribute :column, String, lazy: true, default: :last_seen
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
      contacts = cohort_client.client.processed_service_history&.last_intentional_contacts
      # e.g.: {:project_name=>\"APR - Transitional Housing\", :date=>Mon, 30 Sep 2019, :project_id=>10}
      return unless contacts.present?

      contacts = JSON.parse(contacts)
      contacts.select do |row|
        row['project_id'].in?(user.visible_project_ids_enrollment_context) || row['project_id'].nil?
      end.sort_by { |row| row['date'] }.reverse.map do |row|
        "#{row['project_name']}: #{row['date'].to_date}"
      end.join('; ')
    end
  end
end
