module CohortColumns
  class Ethnicity < ReadOnly
    attribute :column, String, lazy: true, default: :ethnicity
    attribute :title, String, lazy: true, default: 'Ethnicity'


    def value(cohort_client)
      cohort_client.client.source_clients.map(&:Ethnicity)&.select{|v| v.in?([0,1])}&.map do |v|
        ::HUD.ethnicity(v)
      end.uniq&.sort
    end

    def display_read_only user
      if ethnicities = value(cohort_client)
        ethnicities.join('; ')
      end
    end

  end
end
