module CohortColumns
  class Location < Select
    attribute :column, String, lazy: true, default: :location
    attribute :title, String, lazy: true, default: _('Location')

    def available_options
      Rails.cache.fetch("all_project_names", expires_in: 5.minutes) do
        GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
      end
    end

  end
end
