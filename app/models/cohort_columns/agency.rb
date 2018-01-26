module CohortColumns
  class Agency < Base
    attribute :column, String, lazy: true, default: :agency
    attribute :title, String, lazy: true, default: 'Agency'

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
