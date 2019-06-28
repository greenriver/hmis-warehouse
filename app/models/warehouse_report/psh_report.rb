###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::PshReport < WarehouseReport::RrhReport
  include ArelHelper

  def support_for metric, params=nil
    columns = {
      service_project: 'Housing Search',
      search_start: 'Search Start',
      search_end: 'Search End',
      residential_project: 'Stabilization Project',
      housed_date: 'Date Housed',
      housing_exit: 'Housing Exit',
    }

    case metric
    when :enrolled_clients
      rows = enrolled_clients.pluck(*([:client_id] + columns.keys))
    when :enrolled_in_pre_placement
      rows = pre_placement_clients.pluck(*([:client_id] + columns.keys))
    when :enrolled_in_stabilization
      rows = stabilization_clients.pluck(*([:client_id] + columns.keys))
    when :entering_pre_placement
      rows = entering_pre_placement.pluck(*([:client_id] + columns.keys))
    when :exiting_pre_placement
      rows = exiting_pre_placement.pluck(*([:client_id] + columns.keys))
    when :entering_stabilization
      rows = entering_stabilization.pluck(*([:client_id] + columns.keys))
    when :exiting_stabilization
      rows = exiting_stabilization.pluck(*([:client_id] + columns.keys))
    when :pre_placement_stabilization_exit
      project_name = valid_project_name(params[:selected_project])
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement_exit_to_stabilization.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :pre_placement_no_stabilization_exit
      project_name = valid_project_name(params[:selected_project])
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement_exit_no_stabilization.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :pre_placement_any_exit
      project_name = valid_project_name(params[:selected_project])
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :time_in_stabilization
      project_name = valid_project_name(params[:selected_project])
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = in_stabilization.where(residential_project: project_name).
        enrolled_stabilization(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :return_after_exit_to_ph
      columns = {
        housed_date: 'Date Housed',
        housing_exit: 'Housing Exit',
        days_to_return: 'Days to Return',
      }
      bucket = length_of_time_buckets.values.detect do |label|
        params[:bucket] == label
      end
      rows = returns_to_shelter(ph_leavers).select do |_, row|
        row[:bucket] == bucket
      end.map do |_, row|
        [
          row[:client_id],
          row[:entry_date],
          row[:exit_date],
          row[:days_to_return],
        ]
      end
    when :return_after_exit_to_any
      columns = {
        housed_date: 'Date Housed',
        housing_exit: 'Housing Exit',
        days_to_return: 'Days to Return',
      }
      bucket = length_of_time_buckets.values.detect do |label|
        params[:bucket] == label
      end
      rows = returns_to_shelter(exiting_stabilization).select do |_, row|
        row[:bucket] == bucket
      end.map do |_, row|
        [
          row[:client_id],
          row[:entry_date],
          row[:exit_date],
          row[:days_to_return],
        ]
      end
    when :percent_exiting_pre_placement
      columns = {
        service_project: 'Housing Search',
        search_start: 'Search Start',
        search_end: 'Search End',
        housed_date: 'Date Housed',
      }
      project_name = valid_project_name(params[:selected_project])
      month = params[:month]
      support = percent_exiting_pre_placement_data[:support][month][project_name]['data']
      rows = support.map do |row|
        [
          row[:client_id],
          row[:search_start],
          row[:search_end],
          row[:housed_date],
        ]
      end
    when :percent_in_stabilization
      columns = {
        service_project: 'Housing Search',
        search_start: 'Search Start',
        search_end: 'Search End',
        residential_project: 'Stabilization Project',
        housed_date: 'Date Housed',
        housing_exit: 'Housing Exit',
      }
      project_name = valid_project_name(params[:selected_project])
      month = params[:month]
      support = percent_in_stabilization_data[:support][month][project_name]['data']
      rows = support.map do |row|
        [
          row[:client_id],
          row[:service_project],
          row[:search_start],
          row[:search_end],
          row[:residential_project],
          row[:housed_date],
          row[:housing_exit],
        ]
      end
    when :percent_exiting_stabilization
      columns = {
        residential_project: 'Stabilization Project',
        housed_date: 'Date Housed',
        housing_exit: 'Housing Exit',
      }
      project_name = valid_project_name(params[:selected_project])
      month = params[:month]
      support = percent_exiting_stabilization_data[:support][month][project_name]['data']
      rows = support.map do |row|
        [
          row[:client_id],
          row[:residential_project],
          row[:housed_date],
          row[:housing_exit],
        ]
      end
    end

    clients = client_source.where(id: rows.map(&:first)).
        order(:LastName, :FirstName).
        pluck(:id, :FirstName, :LastName)
    Support.new(clients: clients, rows: rows, headers: columns.values)
  end

  def housed_source
    Reporting::Housed.psh
  end
end