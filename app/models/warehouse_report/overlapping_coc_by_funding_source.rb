###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::OverlappingCocByFundingSource < WarehouseReport
  include ArelHelper

  def initialize(coc_code_1:, coc_code_2:, start_date:, end_date:)
    @coc_code_1 = coc_code_1
    @coc_code_2 = coc_code_2
    @start_date = start_date
    @end_date = end_date
  end

  def coc_client_ids(coc_code)
    GrdaWarehouse::ServiceHistoryEnrollment.entry.
      open_between(start_date: @start_date, end_date: @end_date).
      service_within_date_range(start_date: @start_date, end_date: @end_date).
      joins(project: :funders).
      in_coc(coc_code: coc_code).distinct.pluck(:client_id, f_t[:Funder])
  end

  # returns [[client_id, funder]]
  def overlapping_clients
    coc_client_ids(@coc_code_1) & coc_client_ids(@coc_code_2)
  end

  def overlap_by_funding_source
    @overlap_by_funding_source ||= {}.tap do |overlap|
      overlapping_clients.each do |c_id, funder|
        overlap[funder] ||= Set.new
        overlap[funder] << c_id
      end
    end
  end

  def dates_by_funding_source
    @dates_by_funding_source ||= {}.tap do |dates|
      [@coc_code_1, @coc_code_2].each do |coc|
        overlap_by_funding_source.each do |funding_source, clients|
          dates[funding_source] ||= {}
          dates[funding_source][coc] ||= []
          GrdaWarehouse::ServiceHistoryService.joins(service_history_enrollment: {project: [:project_cocs, :funders]}).
            merge(GrdaWarehouse::Hud::Funder.where(Funder: funding_source)).
            service_between(start_date: @start_date, end_date: @end_date).
            where(client_id: clients).
            distinct.
            merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc)).
            pluck(:client_id, f_t[:Funder], :date).each do |c_id, funding_source, date|
              dates[funding_source][coc] << [c_id, date]
            end
        end
      end
    end
  end

  def all_overlapping_clients
    overlapping_clients.map(&:first).uniq.count
  end

  # [
  #   [Project Type, [async_count, concurrent_count]]
  # ]
  def for_chart
    HUD.funding_sources.keys.map do |funding_source|
      async = async_by_funder[funding_source]&.count || 0
      concurrent = concurrent_by_funder[funding_source]&.count || 0
      [
        HUD.funding_source(funding_source),
        [
          async,
          concurrent,
        ]
      ] if (async + concurrent).positive?
    end.compact
  end

  def concurrent_by_funder
    @concurrent_by_funder ||= {}.tap do |concurrent|
      dates_by_funding_source.each do |funding_source, coc_data|
        coc_1 = coc_data.dig(@coc_code_1)
        coc_2 = coc_data.dig(@coc_code_2)

        concurrent[funding_source] ||= []
        concurrent[funding_source] = (coc_1 & coc_2).map(&:first).uniq
      end
    end
  end

  def async_by_funder
    @async_by_funder ||= {}.tap do |async|
      overlap_by_funding_source.each do |funding_source, ids|
        async[funding_source] = ids - concurrent_by_funder[funding_source]
      end
    end
  end
end