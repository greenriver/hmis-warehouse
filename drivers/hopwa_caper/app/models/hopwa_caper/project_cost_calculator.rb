###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper
  class ProjectCostCalculator
    include Memery

    def initialize(report:, cded_key:)
      @report = report
      @cdeds_by_data_source_id = cdeds_by_data_source_id(cded_key)
    end

    # Total cost for a project over the given date range, using the highest
    # daily rate from any active funder on each day.
    def call(project, range)
      schedule = schedule_for(project)
      return 0 if schedule.empty?

      schedule.sum { |day, cost| range.cover?(day) ? cost : 0 }
    end

    private

    def cdeds_by_data_source_id(cded_key)
      return {} unless cded_key

      Hmis::Hud::CustomDataElementDefinition.order(:id).where(key: cded_key).index_by(&:data_source_id)
    end

    # Day-by-day rate map for a project, memoized per project.
    # When funders overlap, the highest rate wins for each day.
    def schedule_for(project)
      result = {}
      cded = @cdeds_by_data_source_id[project.data_source_id]
      return result unless cded

      scope = Hmis::Hud::Funder.where(
        data_source_id: project.data_source_id,
        project_id: project.project_id,
      ).preload(custom_data_elements: :data_element_definition)
      scope.each do |funder|
        rate = funder.custom_data_elements.filter { |cde| cde.data_element_definition == cded }.map(&:value).compact.max
        next unless rate

        # timeline is the intersection of the report period and the funder's active period
        start_date = [@report.start_date, funder.start_date].compact.max
        end_date = [@report.end_date, funder.end_date].compact.min

        (start_date..end_date).each do |day|
          result[day] = [rate, result[day]].compact.max
        end
      end
      result
    end
    memoize :schedule_for
  end
end
