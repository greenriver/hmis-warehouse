module CohortColumns
  class OriginalChronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :original_chronic
    attribute :translation_key, String, lazy: true, default: 'On Original Chronic List'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Manually entered record of original chronic membership'
    end
    
  end
end
