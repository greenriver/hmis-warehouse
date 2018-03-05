module CohortColumns
  class Ineligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :ineligible
    attribute :title, String, lazy: true, default: 'Ineligible'


    def has_default_value?
      true
    end

    def default_value client_id
      false
    end
  end
end
