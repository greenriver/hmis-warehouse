module
  CoreDemographicsReport::PriorCalculations
  extend ActiveSupport::Concern
  included do
    def times_on_street_count(type)
      times_on_street_breakdowns[type]&.count&.presence || 0
    end

    def times_on_street_percentage(type)
      total_count = client_entry_data.count
      return 0 if total_count.zero?

      of_type = times_on_street_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def times_on_street_breakdowns
      @times_on_street_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:times]
      end
    end

    def months_on_street_count(type)
      months_on_street_breakdowns[type]&.count&.presence || 0
    end

    def months_on_street_percentage(type)
      total_count = client_entry_data.count
      return 0 if total_count.zero?

      of_type = months_on_street_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def months_on_street_breakdowns
      @months_on_street_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:months]
      end
    end

    def prior_living_situations_count(type)
      prior_living_situations_breakdowns[type]&.count&.presence || 0
    end

    def prior_living_situations_percentage(type)
      total_count = client_entry_data.count
      return 0 if total_count.zero?

      of_type = prior_living_situations_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def prior_living_situations_breakdowns
      @prior_living_situations_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:living_situation]
      end
    end

    private def client_entry_data
      @client_entry_data ||= {}.tap do |clients|
        report_scope.joins(:enrollment).order(first_date_in_program: :desc).
          distinct.
          pluck(:client_id, e_t[:TimesHomelessPastThreeYears], e_t[:MonthsHomelessPastThreeYears], e_t[:LivingSituation], :first_date_in_program).
          each do |client_id, times_homeless, months_homeless, living_situation, _|
            clients[client_id] ||= {
              times: times_homeless,
              months: months_homeless,
              living_situation: living_situation,
            }
          end
      end
    end
  end
end
