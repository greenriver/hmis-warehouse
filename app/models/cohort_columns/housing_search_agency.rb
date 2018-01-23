module CohortColumns
  class HousingSearchAgency < Base
    attribute :column, String, lazy: true, default: :housing_search_agency
    attribute :title, String, lazy: true, default: 'Housing Search Agency'

    def available_options
      GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
    end

    def default_input_type
      :select2_input
    end
  end
end
