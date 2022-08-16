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

    def self.category
      'Participation'
    end

    def category
      self.class.category
    end

    def display_goal?
      self.class.display_goal?
    end

    def self.display_goal?
      goal_column.present?
    end

    def self.goal_column
      nil
    end

    def display_vispdat_breakdown?
      false
    end

    def display_event_breakdown?
      false
    end

    def goal_unit
      return '%' if unit == 'percent'

      unit
    end

    def gauge_width
      200
    end

    private def max_for_gauge
      [gauge_width, goal, value].max
    end

    def gauge_value
      (value / max_for_gauge * gauge_width).round
    end

    def gauge_target
      (goal / max_for_gauge * gauge_width).round
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

    def hoh_only?
      unit == 'households'
    end

    def clients_for(report:, period:, sub_population: nil, vispdat_range: nil, vispdat_type: nil, event_type: nil)
      return self.class.client_scope(report, period).send(sub_population).preload(:source_client) if sub_population.present?
      return self.class.client_scope(report, period).where(vispdat_range: vispdat_range).preload(:source_client) if vispdat_range.present?
      return self.class.client_scope(report, period).where(vispdat_type: vispdat_type).preload(:source_client) if vispdat_type.present?
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

    def data_for_vispdat_ranges(report)
      @data_for_vispdat_ranges ||= {}.tap do |data|
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

    def data_for_vispdat_types(report)
      @data_for_vispdat_types ||= {}.tap do |data|
        report.vispdat_types.each do |type|
          [
            :reporting,
            :comparison,
          ].each do |period|
            count_scope = self.class.client_scope(report, period).where(vispdat_type: type)
            data[period] ||= {}
            data[period][type] = count_scope.count
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
