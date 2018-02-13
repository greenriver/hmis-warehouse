module CohortColumns
  class HousingPlan < Base
    attribute :column, String, lazy: true, default: :housing_plan
    attribute :title, String, lazy: true, default: 'Housing Plan'

    def default_input_type
      :text
    end

  end
end
