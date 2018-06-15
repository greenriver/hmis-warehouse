module CohortColumns
  class Reported < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :reported
    attribute :title, String, lazy: true, default: 'Reported'
    
  end
end
