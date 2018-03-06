module CohortColumns
  class HousingPlan < ::CohortColumns::Text
    attribute :column, String, lazy: true, default: :housing_plan
    attribute :title, String, lazy: true, default: 'Housing Plan'


  end
end
