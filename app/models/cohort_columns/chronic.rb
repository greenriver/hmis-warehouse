module CohortColumns
  class Chronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :chronic
    attribute :title, String, lazy: true, default: 'On Previous Chronic List'

    def description
      'Manually entered record of previous chronic membership'
    end
    
  end
end
