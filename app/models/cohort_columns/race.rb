module CohortColumns
  class Race < ReadOnly
    attribute :column, String, lazy: true, default: :race
    attribute :title, String, lazy: true, default: 'Race'


    def value(cohort_client)
      cohort_client.client.source_clients.map(&:race_fields)&.flatten&.uniq&.sort
    end

    def display_read_only user
      if races = value(cohort_client)
        races.map do |k|
          ::HUD.races[k]
        end.join('; ')
      end
    end

  end
end
