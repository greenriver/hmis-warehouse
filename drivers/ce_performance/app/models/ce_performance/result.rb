###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Result < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :report

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

    def goal_direction
      ''
    end

    def brief_goal_description
      ''
    end

    def clients_for(report:, period:, sub_population:, vispdat_range:)
      return self.class.client_scope(report, period).send(sub_population).preload(:source_client) if sub_population.present?
      return self.class.client_scope(report, period).where(vispdat_range: vispdat_range).preload(:source_client) if vispdat_range.present?

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
  end
end
