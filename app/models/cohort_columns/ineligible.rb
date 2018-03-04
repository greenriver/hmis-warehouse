module CohortColumns
  class Ineligible < Base
    attribute :column, Boolean, lazy: true, default: :ineligible
    attribute :title, String, lazy: true, default: 'Ineligible'

    def default_input_type
      :boolean
    end

    def has_default_value?
      true
    end

    def default_value client_id
      false
    end
  end
end
