###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::OverlappingCoc < WarehouseReport

  def initialize(coc_code_1:, coc_code_2:, start_date:, end_date:, brakedown:)
    @coc_code_1 = coc_code_1
    @coc_code_2 = coc_code_2
    @start_date = start_date
    @end_date = end_date
    @brakedown = brakedown
  end

  def coc_client_ids(coc_code)
    GrdaWarehouse::ServiceHistoryEnrollment.entry.
      open_between(start_date: @start_date, end_date: @end_date).
        in_coc(coc_code: coc_code).distinct.pluck(:client_id, :computed_project_type)
  end

  def overlapping_clients
    coc_client_ids(@coc_code_1) & coc_client_ids(@coc_code_2)
  end

  def overlap_by_project_type
    @overlap_by_project_type ||= {}.tap do |overlap|
      overlapping_clients.each do |c_id, p_type|
        overlap[p_type] ||= Set.new
        overlap[p_type] << c_id
      end
    end
  end

  def dates_by_p_type
    @dates_by_p_type ||= {}.tap do |dates|
      [@coc_code_1, @coc_code_2].each do |coc|
        overlap_by_project_type.each do |p_type, clients|
          dates[p_type] ||= {}
          dates[p_type][coc] ||= []
          GrdaWarehouse::ServiceHistoryService.joins(service_history_enrollment: {project: :project_cocs}).
            in_project_type(p_type).
            service_between(start_date: @start_date, end_date: @end_date).
            where(client_id: clients).
            distinct.
            merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc)).
            pluck(:client_id, :project_type, :date).each do |c_id, p_type, date|
              dates[p_type][coc] << [c_id, date]
            end
        end
      end
    end
  end

  # [
  #   [Project Type, [async_count, concurrent_count]]
  # ]
  def for_chart
    data = GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten.uniq.map do |p_type|
      async = async_by_type[p_type]&.count || 0
      concurrent = concurrent_by_type[p_type]&.count || 0
      [
        HUD.project_type(p_type),
        [
          async,
          concurrent,
        ]
      ]
    end
  end

  def concurrent_by_type
    @concurrent_by_type ||= {}.tap do |concurrent|
      dates_by_p_type.each do |p_type, coc_data|
        coc_1 = coc_data.dig(@coc_code_1)
        coc_2 = coc_data.dig(@coc_code_2)
        concurrent[p_type] ||= []
        concurrent[p_type] = (coc_1 & coc_2).map(&:first).uniq
      end
    end
  end

  def async_by_type
    @async_by_type ||= {}.tap do |async|
      overlap_by_project_type.each do |p_type, ids|
        async[p_type] = ids - concurrent_by_type[p_type]
      end
    end
  end
end