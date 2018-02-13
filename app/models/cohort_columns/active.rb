module CohortColumns
  class Active < Base
    attribute :column, Boolean, lazy: true, default: :active
    attribute :title, String, lazy: true, default: 'Active'

    def default_input_type
      :boolean
    end

    def has_default_value?
      true
    end

    def default_value client_id
      true
    end
  end
end
