###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LastHomelessVisit < ReadOnly
    attribute :column, String, lazy: true, default: :last_seen
    attribute :translation_key, String, lazy: true, default: 'Last Seen'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Date of last homeless service in ongoing enrollments'
    end

    def display_read_only(user)
      value(cohort_client, user)
    end

    def value_requires_user?
      true
    end

    def value(cohort_client, user) # OK
      lhv = cohort_client.client.processed_service_history&.last_homeless_visit
      # e.g.: {:project_name=>\"APR - Transitional Housing\", :date=>Mon, 30 Sep 2019, :project_id=>10}
      return unless lhv.present?

      enforce_visibility = cohort_client.cohort.enforce_project_visibility_on_cells?
      window_project_ids = GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(GrdaWarehouse::DataSource.visible_in_window).
        pluck(:id)
      lhv = JSON.parse(lhv)
      lhv.select do |row|
        next row['project_id'].in?(user.visible_project_ids_enrollment_context) if enforce_visibility
        next true unless cohort.only_window?

        row['project_id'].in?(window_project_ids)
      end.sort_by { |row| row['date'] }.reverse.map do |row|
        "#{row['project_name']}: #{row['date'].to_date}"
      end.join('; ')
    end
  end
end
