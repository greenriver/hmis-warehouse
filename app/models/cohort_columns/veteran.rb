module CohortColumns
  class Veteran < Base
    attribute :column, String, lazy: true, default: :veteran
    attribute :title, String, lazy: true, default: 'Veteran'

    def default_input_type
      :radio
    end

    def available_options
      ['yes', 'no']
    end
  end
end
