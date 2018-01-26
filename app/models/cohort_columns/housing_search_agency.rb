module CohortColumns
  class HousingSearchAgency < Base
    attribute :column, String, lazy: true, default: :housing_search_agency
    attribute :title, String, lazy: true, default: 'Housing Search Agency'

    def available_options
      Rails.cache.fetch("all_project_names", expires_at: 5.minutes) do
        GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
      end
    end

    def default_input_type
      :select2_input
    end
  end
end
