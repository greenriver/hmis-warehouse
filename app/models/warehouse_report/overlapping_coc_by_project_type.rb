###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

class WarehouseReport::OverlappingCocByProjectType < WarehouseReport
  VERSION = 3
  class Error < ::StandardError; end

  attr_reader :start_date, :end_date, :project_type, :non_overlapping

  extend Memoist

  NON_OVERLAPPING_PROJECT_TYPE = 'non_overlapping'.freeze
  def initialize(coc_code_1:, coc_code_2:, start_date:, end_date:, project_type: nil)
    @coc_code_1 = coc_code_1
    @coc_code_2 = coc_code_2
    @start_date = start_date
    @end_date = end_date

    raise Error, 'This report requires two different COCs.' if coc1 == coc2
    raise Error, "Start date '#{@start_date}' must be before or before end date '#{@end_date}'." if @start_date > @end_date
    raise Error, 'Report duration cannot exceed 3 years.' unless @start_date >= @end_date.prev_year(3)

    if project_type == NON_OVERLAPPING_PROJECT_TYPE
      @non_overlapping = true
    elsif project_type.present?
      @project_type = project_type.to_i
      raise Error, 'Invalid project type' unless ::HUD.project_types.key?(@project_type)
    end

    # FIXME: there is some sort of schema cache issue in development
    GrdaWarehouse::Hud::Client.primary_key = :id
  end

  def cache_key
    {
      report: self.class.name,
      version: VERSION,
      coc_code_1: @coc_code_1,
      coc_code_2: @coc_code_2,
      start_date: @start_date,
      end_date: @end_date,
      project_type: @project_type,
    }.compact
  end

  def time_range
    [start_date, end_date]
  end

  def coc_codes
    [@coc_code_1, @coc_code_2]
  end

  def coc_shape_by_cocnum
    GrdaWarehouse::Shape::CoC.where(cocnum: coc_codes).index_by(&:cocnum)
  end
  memoize :coc_shape_by_cocnum

  def coc1
    coc_shape_by_cocnum[@coc_code_1]
  end

  def coc2
    coc_shape_by_cocnum[@coc_code_2]
  end

  def shared_clients
    GrdaWarehouse::Hud::Client.where(
      id: overlapping_client_ids.map(&:to_i),
    ).select(*['id', 'DOB', 'Ethnicity'] + HUD.gender_fields + GrdaWarehouse::Hud::Client.race_fields)
  end
  memoize :shared_clients

  def coc_client_ids(coc_code)
    scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
      residential.
      open_between(start_date: @start_date, end_date: @end_date).
      service_within_date_range(start_date: @start_date, end_date: @end_date).
      in_coc(coc_code: coc_code)

    if @project_type
      scope = scope.merge(
        GrdaWarehouse::ServiceHistoryEnrollment.where(computed_project_type: @project_type),
      )
    end

    scope.distinct.pluck(:client_id, :computed_project_type)
  end
  memoize :coc_client_ids

  # returns [[client_id, project_type]]
  def client_project_type_pairs
    coc_client_ids(@coc_code_1) & coc_client_ids(@coc_code_2)
  end

  def overlap_by_project_type
    {}.tap do |overlap|
      client_project_type_pairs.each do |c_id, p_type|
        overlap[p_type] ||= Set.new
        overlap[p_type] << c_id
      end
    end
  end
  memoize :overlap_by_project_type

  def service_histories(project_type: nil)
    scope = GrdaWarehouse::ServiceHistoryService.joins(
      service_history_enrollment: {
        project: :project_cocs,
      },
    ).service_between(
      start_date: @start_date,
      end_date: @end_date,
    )

    if project_type
      scope = scope.merge(
        GrdaWarehouse::ServiceHistoryEnrollment.where(computed_project_type: @project_type),
      )
    end
    scope
  end

  def dates_by_p_type
    {}.tap do |dates|
      coc_codes.each do |coc|
        overlap_by_project_type.each do |p_type, clients|
          dates[p_type] ||= {}
          dates[p_type][coc] ||= []
          service_histories(project_type: @project_type).
            where(client_id: clients).
            in_project_type(p_type).
            distinct.
            merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc)).
            pluck(:client_id, :project_type, :date).each do |c_id, p_type2, date|
              dates[p_type2][coc] << [c_id, date]
            end
        end
      end
    end
  end
  memoize :dates_by_p_type

  def overlapping_client_ids
    (coc_client_ids(@coc_code_1).map(&:first) & coc_client_ids(@coc_code_2).map(&:first))
  end

  def total_shared_clients
    overlapping_client_ids.size
  end

  def total_non_overlapping_clients
    non_overlapping_client_ids.size
  end

  def non_overlapping_client_ids
    overlapping_client_ids - (concurrent_by_type.values.flatten + async_by_type.values.map(&:to_a).flatten).uniq
  end

  def details_hash
    {
      start_date: start_date.iso8601,
      end_date: end_date.iso8601,
      cocs: [coc1, coc2].map do |coc|
        { code: coc.cocnum, name: coc.cocname }
      end,
      clients: details_clients,
    }
  end

  def details_clients
    client_num = 0
    clients_by_id = shared_clients.index_by(&:id)
    relevant_client_ids = @non_overlapping ? non_overlapping_client_ids : overlapping_client_ids
    service_histories.where(client_id: relevant_client_ids).
      group_by(&:client_id).map do |client_id, _|
        client = clients_by_id[client_id]
        {
          label: "Client ##{client_num += 1}",
          gender: client.gender,
          age_group: age_group(client),
          race: client.race_description,
          ethnicity: ::HUD.ethnicity(client.Ethnicity),
          client_id: client.to_param,
        }
      end
  end

  def limited_details_hash
    {
      start_date: start_date.iso8601,
      end_date: end_date.iso8601,
      cocs: [coc1, coc2].map do |coc|
        { code: coc.cocnum, name: coc.cocname }
      end,
      clients: limited_details_clients,
    }
  end

  def limited_details_clients
    client_num = 0
    clients_by_id = shared_clients.index_by(&:id)
    relevant_client_ids = @non_overlapping ? non_overlapping_client_ids : overlapping_client_ids
    # force this to only return data for the first 50, beyond that is unnecessary
    relevant_client_ids = relevant_client_ids[0..50]
    service_histories.where(client_id: relevant_client_ids).
      preload(
        service_history_enrollment: {
          project: :project_cocs,
        },
      ).
      group_by(&:client_id).map do |client_id, services|
        client = clients_by_id[client_id]
        {
          label: "Client ##{client_num += 1}",
          gender: client.gender,
          age_group: age_group(client),
          race: client.race_description,
          ethnicity: ::HUD.ethnicity(client.Ethnicity),
          enrollments: enrollment_details(services),
          client_id: client.to_param,
        }
      end
  end

  # FIXME: stolen from GrdaWarehouse::ServiceHistoryEnrollment.available_age_ranges
  # Based on age as of the start of of the report period
  private def age_group(client)
    return 'Unknown age' unless client.age&.positive?

    case client.age(start_date)
    when 0..17
      'Under 18'
    when 18..24
      'Age 18 - 24'
    when 25..61
      'Age 25 - 61'
    when 62..10_000
      'Age 62+'
    end
  end

  private def enrollment_details(services)
    services.group_by { |s| s.service_history_enrollment.project }.map do |project, project_services|
      {
        coc: project.project_cocs.first.CoCCode,
        project_name: project.name(ignore_confidential_status: true),
        project_type: ::HUD.project_type_brief(project.ProjectType),
        history: history_details(project_services),
      }
    end.sort_by do |service|
      service[:history][0][:from]
    rescue StandardError
      Date.new(1, 1, 0)
    end.reverse
  end

  private def history_details(services)
    services.compact.sort_by(&:date).slice_when do |i, j|
      (i.date - j.date).abs > 1
    end.map do |seq|
      label = if seq.length == 1
        seq.first.date
      else
        "#{seq.first.date}-#{seq.last.date}"
      end
      { from: seq.first.date.beginning_of_day.iso8601, to: seq.last.date.end_of_day.iso8601, label: label }
    end
  end

  # [
  #   [Project Type, [async_count, concurrent_count]]
  # ]
  def chart_by_project_type
    GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten.uniq.map do |p_type|
      async = async_by_type[p_type]&.count || 0
      concurrent = concurrent_by_type[p_type]&.count || 0
      next unless (async + concurrent).positive?

      [
        HUD.project_type(p_type),
        [
          async,
          concurrent,
        ],
        p_type,
      ]
    end.compact
  end

  def for_chart
    chart_by_project_type
  end

  def concurrent_by_type
    {}.tap do |concurrent|
      dates_by_p_type.each do |p_type, coc_data|
        coc_1 = coc_data.dig(@coc_code_1)
        coc_2 = coc_data.dig(@coc_code_2)

        concurrent[p_type] ||= []
        concurrent[p_type] = (coc_1 & coc_2).map(&:first).uniq
      end
    end
  end
  memoize :concurrent_by_type

  def async_by_type
    {}.tap do |async|
      overlap_by_project_type.each do |p_type, ids|
        async[p_type] = ids - concurrent_by_type[p_type]
      end
    end
  end
  memoize :async_by_type
end
