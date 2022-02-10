###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::PriorCalculations
  extend ActiveSupport::Concern
  included do
    def prior_detail_hash
      {}.tap do |hashes|
        ::HUD.times_homeless_options.each do |id, title|
          hashes["prior_times_#{id}"] = {
            title: "Number of Times on the Streets, ES, or SH in The Past 3 Years #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_prior_times(id)).distinct },
          }
        end
        ::HUD.month_categories.each do |id, title|
          hashes["prior_months_#{id}"] = {
            title: "Number of Months on the Streets, ES, or SH in The Past 3 Years #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_prior_months(id)).distinct },
          }
        end
        ::HUD.living_situations.each do |id, title|
          hashes["prior_situation_#{id}"] = {
            title: "Prior Living Situation #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_prior_situation(id)).distinct },
          }
        end
      end
    end

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

    private def client_ids_in_prior_times(key)
      times_on_street_breakdowns[key]&.map(&:first)
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

    private def client_ids_in_prior_months(key)
      months_on_street_breakdowns[key]&.map(&:first)
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

    private def client_ids_in_prior_situation(key)
      prior_living_situations_breakdowns[key]&.map(&:first)
    end

    def priors_data_for_export(rows)
      rows['_Number of Times on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Times on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Times Response'] ||= []
      rows['*Number of Times Response'] += ['Times', 'Count', 'Percentage', nil, nil]
      ::HUD.times_homeless_options.each do |id, title|
        rows["_Number of Times Response_data_#{title}"] ||= []
        rows["_Number of Times Response_data_#{title}"] += [
          title,
          times_on_street_count(id),
          times_on_street_percentage(id) / 100,
          nil,
        ]
      end
      rows['_Number of Months on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Months on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Months Response'] ||= []
      rows['*Number of Months Response'] += ['Time', 'Count', 'Percentage', nil, nil]
      ::HUD.month_categories.each do |id, title|
        rows["_Number of Months_data_#{title}"] ||= []
        rows["_Number of Months_data_#{title}"] += [
          title,
          months_on_street_count(id),
          months_on_street_percentage(id) / 100,
          nil,
        ]
      end
      rows['_Prior Living Situation break'] ||= []
      rows['*Prior Living Situation'] ||= []
      rows['*Prior Living Situation'] += ['Situation', 'Count', 'Percentage', nil, nil]
      ::HUD.living_situations.each do |id, title|
        rows["_Prior Living Situation_data_#{title}"] ||= []
        rows["_Prior Living Situation_data_#{title}"] += [
          title,
          prior_living_situations_count(id),
          prior_living_situations_percentage(id) / 100,
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
