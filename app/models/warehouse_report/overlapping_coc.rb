###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

class WarehouseReport::OverlappingCoc < WarehouseReport
  VERSION = 0
  class Error < ::StandardError; end
  include ArelHelper

  attr_reader :start_date, :end_date, :coc_code

  def initialize(coc_code:, start_date:, end_date:)
    @coc_code = coc_code
    @start_date = start_date
    @end_date = end_date

    raise Error, "Start date '#{@start_date}' must be before or before end date '#{@end_date}'." if @start_date > @end_date
    raise Error, 'Report duration cannot exceed 3 years.' unless @start_date >= @end_date.prev_year(3)
  end

  def results
    e_scope = GrdaWarehouse::ServiceHistoryEnrollment.
      entry.
      residential.
      open_between(
        start_date: start_date,
        end_date: end_date,
      ).
      service_within_date_range(
        start_date: start_date,
        end_date: end_date,
      )

    my_enrollments = e_scope.in_coc(
      coc_code: coc_code,
    )

    my_client_ids = my_enrollments.distinct.pluck(:client_id)

    other_client_counts = e_scope.where(
      client_id: my_client_ids,
    ).where.not(
      id: my_enrollments.select(:id),
    ).joins(project: :project_cocs).group(
      GrdaWarehouse::Hud::ProjectCoc.coc_code_coalesce.to_sql,
    ).distinct.count(:client_id)

    other_client_counts
  end

  def time_range
    [start_date, end_date]
  end
end
