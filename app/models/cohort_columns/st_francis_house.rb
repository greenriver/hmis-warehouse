module CohortColumns
  class StFrancisHouse < Base
    attribute :column, String, lazy: true, default: :st_francis_house
    attribute :title, String, lazy: true, default: 'St. Francis House '

    def default_input_type
      :select
    end

    def available_options
      ['Infrequent Visitor', 'Frequent Visitor', 'Case Management']
    end

  end
end
