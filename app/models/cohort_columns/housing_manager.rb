module CohortColumns
  class HousingManager < Base
    attribute :column, String, lazy: true, default: :housing_manager
    attribute :title, String, lazy: true, default: 'Housing Manager'

  end
end