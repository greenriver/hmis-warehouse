module CohortColumns
  class DestinationFromHomelessness < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :destination_from_homelessness
    attribute :title, String, lazy: true, default: 'Recent Exits from Homelessness'
    attribute :editable, Boolean, lazy: false, default: false

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      effective_date = cohort.effective_date || Date.today
      cohort_client.client.
        permanent_source_exits_from_homelessness.
        where(ex_t[:ExitDate].gteq(90.days.ago.to_date)).
        pluck(:ExitDate, :Destination).map do |exit_date, destination|
          "#{exit_date} to #{HUD.destination(destination)}"
        end.join('; ')
     
    end
  end
end
