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

    def priors_data_for_export(rows)
      rows['_Number of Times on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Times on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Times Reponse'] ||= []
      rows['*Number of Times Reponse'] += ['Count', 'Percentage', nil, nil]
      ::HUD.yes_no_missing_options.each do |id, title|
        rows["_Number of Times Reponse#{title}"] ||= []
        rows["_Number of Times Reponse#{title}"] += [
          title,
          times_on_street_count(id),
          times_on_street_percentage(id),
          nil,
        ]
      end
      rows['_Number of Months on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Months on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Months Reponse'] ||= []
      rows['*Number of Months Reponse'] += ['Count', 'Percentage', nil, nil]
      ::HUD.month_categories.each do |id, title|
        rows["_Number of Months#{title}"] ||= []
        rows["_Number of Months#{title}"] += [
          title,
          months_on_street_count(id),
          months_on_street_percentage(id),
          nil,
        ]
      end
      rows['_Prior Living Situation break'] ||= []
      rows['*Prior Living Situation'] ||= []
      rows['*Prior Living Situation'] += ['Count', 'Percentage', nil, nil]
      ::HUD.month_categories.each do |id, title|
        rows["_Prior Living Situation#{title}"] ||= []
        rows["_Prior Living Situation#{title}"] += [
          title,
          prior_living_situations_count(id),
          prior_living_situations_percentage(id),
          nil,
        ]
      end
      rows
    end

    private def prior_living_situations_breakdowns
      @prior_living_situations_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:living_situation]
      end
    end

    private def client_entry_data
      @client_entry_data ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
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
end
