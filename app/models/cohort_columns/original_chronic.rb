module CohortColumns
  class OriginalChronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :original_chronic
    attribute :title, String, lazy: true, default: 'On Original Chronic List'

    def description
      'Manually entered record of original chronic membership'
    end
    
  end
end
