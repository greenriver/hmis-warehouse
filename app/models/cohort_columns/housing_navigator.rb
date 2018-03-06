module CohortColumns
  class HousingNavigator < CohortString
    attribute :column, String, lazy: true, default: :housing_navigator
    attribute :title, String, lazy: true, default: 'Housing Navigator'


  end
end
