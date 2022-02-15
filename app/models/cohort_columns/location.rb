###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Location < Select
    attribute :column, String, lazy: true, default: :location
    attribute :translation_key, String, lazy: true, default: 'Location'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def available_options
      Rails.cache.fetch('all_project_names', expires_in: 5.minutes) do
        GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
      end
    end
  end
end
