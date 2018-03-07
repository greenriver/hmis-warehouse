module CohortColumns
  class Chronic < Radio
    attribute :column, Boolean, lazy: true, default: :chronic
    attribute :title, String, lazy: true, default: 'On Previous Chronic List'


  end
end
