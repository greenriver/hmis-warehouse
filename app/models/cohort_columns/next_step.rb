module CohortColumns
  class NextStep < CohortString
    attribute :column, String, lazy: true, default: :next_step
    attribute :title, String, lazy: true, default: 'Next Step'


  end
end
