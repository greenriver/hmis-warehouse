###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Result < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :report

    def self.available_event_ids
      ::HUD.events.keys
    end

    def nested_header
      'Breakdowns'
    end

    def nested_results
      []
    end

    def category
      'Participation'
    end

    def display_goal?
      true
    end

    def display_vispdat_breakdown?
      false
    end

    def display_event_breakdown?
      false
    end

    def goal_direction
      ''
    end

    def brief_goal_description
      ''
    end

    def overview
      true
    end

    def clients_for(report:, period:, sub_population: nil, vispdat_range: nil, event_type: nil)
      return self.class.client_scope(report, period).send(sub_population).preload(:source_client) if sub_population.present?
      return self.class.client_scope(report, period).where(vispdat_range: vispdat_range).preload(:source_client) if vispdat_range.present?
      return self.class.client_scope(report, period).preload(:source_client).with_event_type(event_type) if event_type.present?

      self.class.client_scope(report, period).preload(:source_client)
    end

    def data_for_subpopulations(report)
      @data_for_subpopulations ||= {}.tap do |data|
        CePerformance::Client.subpopulations(report).each do |title, scope|
          [
            :reporting,
            :comparison,
          ].each do |period|
            count_scope = self.class.client_scope(report, period)
            count_scope = count_scope.send(scope) if scope
            data[period] ||= {}
            data[period][title] = count_scope.count
          end
        end
      end
    end

    def data_for_vispdats(report)
      @data_for_vispdats ||= {}.tap do |data|
        report.vispdat_ranges.each do |range|
          [
            :reporting,
            :comparison,
          ].each do |period|
            count_scope = self.class.client_scope(report, period).where(vispdat_range: range)
            data[period] ||= {}
            data[period][range] = count_scope.count
          end
        end
      end
    end

    def data_for_events(report)
      @data_for_events ||= {}.tap do |data|
        self.class.available_event_ids.each do |event_id|
          [
            :reporting,
            :comparison,
          ].each do |period|
            data[period] ||= {}
            data[period][::HUD.event(event_id)] = self.class.find_by(report_id: report.id, period: period, event_type: event_id)&.value
          end
        end
      end
    end
  end
end
