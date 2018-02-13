module CohortColumns
  class Provider < Base
    attribute :column, String, lazy: true, default: :provider
    attribute :title, String, lazy: true, default: 'Provider'

    def default_input_type
      :string
    end

  end
end
