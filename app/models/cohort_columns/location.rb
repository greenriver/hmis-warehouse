module CohortColumns
  class Location < Base
    attribute :column, String, lazy: true, default: :location
    attribute :title, String, lazy: true, default: 'Location'

    def available_options
      Rails.cache.fetch("all_project_names", expires_at: 5.minutes) do
        GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
      end
    end

    def default_input_type
      :select2
    end
  end
end
