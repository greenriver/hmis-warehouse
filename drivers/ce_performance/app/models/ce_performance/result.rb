###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Result < GrdaWarehouseBase
    include ActionView::Helpers::NumberHelper
    acts_as_paranoid

    belongs_to :report

    def self.available_event_ids
      ::HudUtility2024.events.keys
    end

    def self.available_exit_destination_ids
      ::HudUtility2024.destinations.keys
    end

    def nested_header
      'Breakdowns'
    end

    def nested_results
      []
    end

    def sub_results
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

    def display_exit_breakdown?
      false
    end

    def goal_unit
      return '%' if unit == 'percent'

      unit
    end

    def goal_progress(_comparison)
      value&.round
    end

    def gauge_width
      200
    end

    private def gauge_max
      100
    end

    private def gauge_ratio
      (gauge_width / 120.to_f) # to allow roughly 120 to show on the gauge
    end

    def gauge_value(comparison)
      v = goal_progress(comparison)
      return 0 unless v.present?

      (v.clamp(0, 120) * gauge_ratio).round
    end

    def gauge_target
      goal * gauge_ratio
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

    def clients_for(report:, period:, sub_population: nil, vispdat_range: nil, vispdat_type: nil, event_type: nil, exit_type: nil)
      return self.class.client_scope(report, period).send(sub_population).preload(:source_client) if sub_population.present?
      return self.class.client_scope(report, period).where(vispdat_range: vispdat_range).preload(:source_client) if vispdat_range.present?
      return self.class.client_scope(report, period).where(vispdat_type: vispdat_type).preload(:source_client) if vispdat_type.present?
      return self.class.client_scope(report, period).preload(:source_client).with_event_type(event_type) if event_type.present?
      return self.class.client_scope(report, period).preload(:source_client).in_exit_destination(exit_type) if exit_type.present?

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
            data[period][::HudUtility2024.event(event_id)] = self.class.find_by(report_id: report.id, period: period, event_type: event_id)&.value
          end
        end
      end
    end

    def data_for_exits(report)
      @data_for_exits ||= {}.tap do |data|
        self.class.available_exit_destination_ids.each do |exit_id|
          [
            :reporting,
            :comparison,
          ].each do |period|
            data[period] ||= {
              'CePerformance::Results::ExitHomeless' => {},
              'CePerformance::Results::ExitInstitutional' => {},
              'CePerformance::Results::ExitTemporary' => {},
              'CePerformance::Results::ExitPermanent' => {},
              'CePerformance::Results::ExitOther' => {},
            }
            data[period]['CePerformance::Results::ExitHomeless'][::HudUtility2024.destination(exit_id)] = self.class.client_scope(report, period).in_exit_destination(exit_id).count if ::HudUtility2024.homeless_destinations.include?(exit_id)
            data[period]['CePerformance::Results::ExitInstitutional'][::HudUtility2024.destination(exit_id)] = self.class.client_scope(report, period).in_exit_destination(exit_id).count if ::HudUtility2024.institutional_destinations.include?(exit_id)
            data[period]['CePerformance::Results::ExitTemporary'][::HudUtility2024.destination(exit_id)] = self.class.client_scope(report, period).in_exit_destination(exit_id).count if ::HudUtility2024.temporary_destinations.include?(exit_id)
            data[period]['CePerformance::Results::ExitPermanent'][::HudUtility2024.destination(exit_id)] = self.class.client_scope(report, period).in_exit_destination(exit_id).count if ::HudUtility2024.permanent_destinations.include?(exit_id)
            data[period]['CePerformance::Results::ExitOther'][::HudUtility2024.destination(exit_id)] = self.class.client_scope(report, period).in_exit_destination(exit_id).count if ::HudUtility2024.other_destinations.include?(exit_id)
          end
        end
      end
    end
  end
end
