module CohortColumns
  class StFrancisHouse < Select
    attribute :column, String, lazy: true, default: :st_francis_house
    attribute :title, String, lazy: true, default: 'St. Francis House'

  end
end
