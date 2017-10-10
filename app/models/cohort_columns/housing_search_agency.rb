module CohortColumns
  class HousingSearchAgency < Base
    attribute :column, String, lazy: true, default: :housing_search_agency
    attribute :title, String, lazy: true, default: 'Housing Search Agency'

  end
end