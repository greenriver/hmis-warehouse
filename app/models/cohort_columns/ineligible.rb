module CohortColumns
  class Ineligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :ineligible
    attribute :translation_key, String, lazy: true, default: 'Ineligible'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def has_default_value?
      true
    end

    def default_value client_id
      false
    end
  end
end
