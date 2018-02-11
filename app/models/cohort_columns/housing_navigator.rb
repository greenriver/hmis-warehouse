module CohortColumns
  class HousingNavigator < Base
    attribute :column, String, lazy: true, default: :housing_navigator
    attribute :title, String, lazy: true, default: 'Housing Navigator'

    def default_input_type
      :string
    end
  end
end
