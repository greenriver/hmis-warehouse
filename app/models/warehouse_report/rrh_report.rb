###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::RrhReport
  include ArelHelper

  attr_accessor :project_ids, :start_date, :end_date, :subpopulation, :household_type, :race, :ethnicity, :gender, :veteran_status
  def initialize project_ids:, start_date:, end_date:, subpopulation:, household_type:, race:, ethnicity:, gender:, veteran_status:
    @project_ids = project_ids
    @start_date = start_date
    @end_date = end_date
    @subpopulation = Reporting::Housed.subpopulation(subpopulation)
    @household_type = Reporting::Housed.household_type(household_type)
    @race = Reporting::Housed.race(race)
    @ethnicity = Reporting::Housed.ethnicity(ethnicity)
    @gender = Reporting::Housed.gender(gender)
    @veteran_status = Reporting::Housed.veteran_status(veteran_status)
  end

  def pre_placement_project_name
    @pre_placement_project_name ||= unless all_projects
      housed_scope.where.not(service_project: nil).
        where.not(service_project: 'No Service Enrollment').
        distinct.
        pluck(:service_project).
        join(', ')
    else
      ''
    end
  end

  def stabilization_project_name
    @stabilization_project_name ||= unless all_projects
      housed_scope.where.not(residential_project: nil).
        distinct.
        pluck(:residential_project).
        join(', ')
    else
      ''
    end
  end

  def project_names
    @project_names ||=
    (
      pre_placement_project_name.split(', ') +
      stabilization_project_name.split(', ')
    ).uniq.
      join(', ')
  end

  def service_project_names
    @service_project_names ||= housed_scope.distinct.pluck(:service_project)
  end

  def residential_project_names
    @residential_project_names ||= housed_scope.distinct.pluck(:residential_project)
  end

  # newly enrolled during date range
  def entering_pre_placement
    housed_scope.entering_pre_placement(start_date: start_date, end_date: end_date).
      distinct
  end

  # exited pre-placement during date range if two projects
  # received move-in-date if one project
  def exiting_pre_placement
    housed_scope.exiting_pre_placement(start_date: start_date, end_date: end_date).
      distinct
  end

  def entering_stabilization
    housed_scope.entering_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def exiting_stabilization
    housed_scope.exiting_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def days_in_pre_placement
    @days_in_pre_placement ||= housed_scope.
      enrolled_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:search_start, :search_end)
  end

  def average_days_in_pre_placement
    days = days_in_pre_placement.map do |entry_date, exit_date|
      exit_date ||= end_date
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / days_in_pre_placement.count).round
  end

  def days_in_stabilization
    @days_in_stabilization ||= housed_scope.
      enrolled_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:housed_date, :housing_exit)
  end

  def average_days_in_stabilization
    days = days_in_stabilization.map do |entry_date, exit_date|
      exit_date ||= end_date
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / days_in_stabilization.count).round
  end

  def leavers_pre_placement
    @leavers_pre_placement ||= housed_scope.
      leavers_pre_placement(start_date: start_date, end_date: end_date).
      distinct
  end

  def leavers_pre_placement_exit_to_stabilization
    @leavers_pre_placement_exit_to_stabilization ||= housed_scope.
      exited_pre_placement_to_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def average_days_leavers_pre_placement_exit_to_stabilization
    days = leavers_pre_placement_exit_to_stabilization.pluck(:search_start, :search_end).map do |entry_date, exit_date|
      exit_date ||= end_date
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_pre_placement_exit_to_stabilization.count).round
  end

  def leavers_pre_placement_exit_no_stabilization
    @leavers_pre_placement_exit_no_stabilization ||= housed_scope.
      exited_pre_placement_no_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def average_days_leavers_pre_placement_exit_no_stabilization
    days = leavers_pre_placement_exit_no_stabilization.pluck(:search_start, :search_end).map do |entry_date, exit_date|
      exit_date ||= end_date
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_pre_placement_exit_no_stabilization.count).round
  end

  def leavers_average_pre_placement
    days = leavers_pre_placement.pluck(:search_start, :search_end).map do |entry_date, exit_date|
      (exit_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_pre_placement.count).round
  end

  def stayers_days_in_pre_placement
    @stayers_days_in_pre_placement ||= housed_scope.
      stayers_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:search_start).compact.map do |entry_date|
        [entry_date, end_date]
      end
  end

  def stayers_average_days_in_pre_placement
    days = stayers_days_in_pre_placement.map do |entry_date, exit_date|
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / stayers_days_in_pre_placement.count).round
  end

  def leavers_days_in_stabilization
    @leavers_days_in_stabilization ||= housed_scope.
      leavers_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:housed_date, :housing_exit)
  end

  def leavers_average_days_in_stabilization
    days = leavers_days_in_stabilization.map do |entry_date, exit_date|
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_days_in_stabilization.count).round
  end

  def stayers_days_in_stabilization
    @stayers_days_in_stabilization ||= housed_scope.
      stayers_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      where.not(housed_date: nil).
      pluck(:housed_date).compact.map do |entry_date|
        [entry_date, end_date]
      end
  end

  def stayers_average_days_in_stabilization
    days = stayers_days_in_stabilization.map do |entry_date, exit_date|
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / stayers_days_in_stabilization.count).round
  end

  def in_stabilization
    @in_stabilization ||= housed_scope.
      enrolled_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def leavers_days
    @leavers_days ||= housed_scope.
      leavers(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:search_start, :housing_exit)
  end

  def leavers_average_days
    days = leavers_days.map do |entry_date, exit_date|
      (exit_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_days.count).round
  end

  def stayers_days
    @stayers_days ||= housed_scope.
      stayers(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:search_start).compact.map do |entry_date|
        [entry_date, end_date]
      end
  end

  def stayers_average_days
    days = stayers_days.map do |entry_date, exit_date|
      (exit_date.to_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / stayers_days.count).round
  end

  def destinations
    @destinations ||= begin
      @destinations = {}
      destinations = {
        'returned to shelter' => {},
        'exited to other institution' => {},
        'successful exit to PH' => {},
        'exited to temporary destination' => {},
        'other or unknown outcome' => {},
      }
      columns = [
        :client_id,
        :residential_project,
        :destination,
        :housed_date,
        :housing_exit,
      ]
      housed_scope.
        exiting_stabilization(start_date: start_date, end_date: end_date).
        where(ho_t[:destination].not_eq(nil)).
        distinct.
        pluck(*columns).map do |row|
          row = Hash[columns.zip(row)]
          destination = destination_bucket(row[:client_id], row[:destination])
          destinations[destination][:destination] ||= destination_bucket(row[:client_id], row[:destination])
          destinations[destination][:count] ||= 0
          destinations[destination][:client_ids] ||= Set.new
          # Only count each client once per bucket
          destinations[destination][:count] += 1 unless destinations[destination][:client_ids].include?(row[:client_id])
          destinations[destination][:client_ids] << row[:client_id]
          destinations[destination][:detailed_destinations] ||= {}
          destinations[destination][:detailed_destinations][HUD.destination(row[:destination])] ||= 0
          destinations[destination][:detailed_destinations][HUD.destination(row[:destination])] += 1

          # Support for later
          destinations[destination][:support] ||= []
          destinations[destination][:support] << row
        end
      destinations.delete_if{|_,v| v == {} }
      @destinations[:support] = destinations
      @destinations[:projects_selected] = ! all_projects
      @destinations[:data] = destinations.map{|_, row| [row[:destination], row[:count]]}
      @destinations
    end
  end

  def destination_bucket client_id, dest_id
    return 'returned to shelter' if returns_to_shelter_after_ph.keys.include?(client_id)
    return 'exited to other institution' if HUD.institutional_destinations.include?(dest_id)
    return 'successful exit to PH' if HUD.permanent_destinations.include?(dest_id)
    return 'exited to temporary destination' if HUD.temporary_destinations.include?(dest_id)
    return 'other or unknown outcome'
  end

  def ph_leavers
    exiting_stabilization.ph_destinations
  end

  def returns_to_shelter_after_ph
    @returns_to_shelter_after_ph ||= returns_to_shelter(ph_leavers)
  end

  def returns_to_shelter_after_exit
    @returns_to_shelter_after_exit ||= returns_to_shelter(exiting_stabilization)
  end

  # returns to shelter after exiting to permanent housing
  def returns_to_shelter leaver_scope
    @returns_to_shelter = begin
      leavers_with_date = leaver_scope.pluck(:client_id, :housing_exit).to_h
      return {} unless leavers_with_date.present?
      returner_ids = Reporting::Return.where(client_id: leavers_with_date.keys).distinct.pluck(:client_id)
      rr_t = Reporting::Return.arel_table
      returns = {}
      returner_ids.each do |id|
        # find the first start date after the exit to PH
        first_return = min_return_date_for_client_after(id, leavers_with_date[id])
        if first_return.present?
          exit_date = leavers_with_date[id]
          days_to_return = (first_return - exit_date).to_i.abs
          returns[id] = {
            entry_date: first_return,
            exit_date: leavers_with_date[id],
            days_to_return: days_to_return,
            bucket: bucket(days_to_return),
            client_id: id,
          }
        end
      end
      returns
    end
  end

  def min_return_date_for_client_after client_id, date
    @entry_dates_by_client ||= begin
      dates_by_client = {}
      Reporting::Return.distinct.
        order(first_date_in_program: :asc).
        pluck(:client_id, :first_date_in_program).
        each do |id, date|
          dates_by_client[id] ||= []
          dates_by_client[id] << date
        end
      dates_by_client
    end
    @entry_dates_by_client[client_id]&.detect{|d| d > date}
  end

  def percent_returns_to_shelter leaver_scope
    return 0 unless leaver_scope.exists?
    (returns_to_shelter(leaver_scope).uniq.count.to_f/leaver_scope.select(:client_id).count * 100).round(2)
  end

  def percent_returns_to_shelter_after_ph_exit
    percent_returns_to_shelter(ph_leavers)
  end

  def percent_returns_to_shelter_after_any_exit
    percent_returns_to_shelter(exiting_stabilization)
  end

  def bucketed_returns
    @bucketed_returns ||= {}
    grouped_returns = returns_to_shelter_after_exit.values.group_by{|m| m[:bucket]}
    length_of_time_buckets.each do |_, bucket_text|
      if grouped_returns[bucket_text].present?
        @bucketed_returns[bucket_text] = grouped_returns[bucket_text].count
      end
    end
    return @bucketed_returns.to_a
  end

  def ph_bucketed_returns
    @ph_bucketed_returns ||= {}
    grouped_returns = returns_to_shelter_after_ph.values.group_by{|m| m[:bucket]}
    length_of_time_buckets.each do |_, bucket_text|
      if grouped_returns[bucket_text].present?
        @ph_bucketed_returns[bucket_text] = grouped_returns[bucket_text].count
      end
    end
    return @ph_bucketed_returns.to_a
  end

  def ph_returns_for_chart
    {
      labels: ph_bucketed_returns.map(&:first),
      data: [['Client count'] + ph_bucketed_returns.map(&:last)],
      projects_selected: ! all_projects,
    }
  end

  def returns_for_chart
    {
      labels: bucketed_returns.map(&:first),
      data: [['Client count'] + bucketed_returns.map(&:last)],
      projects_selected: ! all_projects,
    }
  end

  def time_in_pre_placement_exit_to_stabilization_data
    support = pre_placement_average_stay_by_month(leavers_pre_placement_exit_to_stabilization)
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support),
      support: support,
    }
  end

  def time_in_pre_placement_exit_no_stabilization_data
    support = pre_placement_average_stay_by_month(leavers_pre_placement_exit_no_stabilization)
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support),
      support: support,
    }
  end

  def time_in_pre_placement_leavers_data
    support = pre_placement_average_stay_by_month(leavers_pre_placement)
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support),
      support: support,
    }
  end

  def time_in_stabilization_data
    support = stabilization_average_stay_by_month(in_stabilization)
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support),
      support: support,
    }
  end

  def percent_exiting_pre_placement_data
    support = percent_exiting_pre_placement_to_stabilization_by_month
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support, 'percentage'),
      support: support,
    }
  end

  def percent_in_stabilization_data
    support = percent_in_stabilization_by_month
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support, 'percentage'),
      support: support,
    }
  end

  def percent_exiting_stabilization_data
    support = percent_exiting_stabilization_to_housing_by_month
    months = months_for(start_date: start_date, end_date: end_date)
    {
      labels: ['x'] + months,
      data: [['x'] + months] + data_from(months, support, 'percentage'),
      support: support,
    }
  end

  # Supporting methods

  def data_from months, support, key='average'
    data = {}
    project_names = support.values.map(&:keys).flatten.uniq
    project_names.each do |project_name|
      months.each do |month|
        d = support[month][project_name]
        data[project_name] ||= [project_name.gsub(/ - \(\d+\)$/, '')]
        data[project_name] << (d.try(:[], key) || 0)
      end
    end
    return data.values
  end

  def months_for start_date:, end_date:
    (start_date.to_date..end_date.to_date).map{ |m| m.strftime('%b %Y') }.uniq
  end

  # Denominator: count exiting pre-placement
  def percent_exiting_pre_placement_to_stabilization_by_month
    columns = [:search_start, :search_end, :service_project, :housed_date, :client_id]

    denominators = {}
    exiting_pre_placement.group_by{|m| m[:service_project]}.map do |project_name, rows|
      months_for(start_date: start_date, end_date: end_date).each do |month_year|
        beginning_of_month = Date.parse "#{month_year} 01"
        end_of_month = beginning_of_month.end_of_month
        denominators[month_year] ||= {}
        # limit to those who exited in the month
        denominators[month_year][project_name] = rows.count do |row|
          row.search_end.present? && row.search_end >= beginning_of_month && row.search_end <= end_of_month
        end
        denominators[month_year]['All'] ||= 0
        denominators[month_year]['All'] += denominators[month_year][project_name]
      end
    end

    client_scope = leavers_pre_placement_exit_to_stabilization
    clients = client_scope.pluck(*columns).map do |row|
      Hash[columns.zip(row)]
    end.group_by do |row|
      row[:service_project]
    end
    month_data = {}
    months_for(start_date: start_date, end_date: end_date).each do |month_year|
      beginning_of_month = Date.parse "#{month_year} 01"
      end_of_month = beginning_of_month.end_of_month

      month_data[month_year] ||= {}
      month_data[month_year]['All'] ||= {}
      month_data[month_year]['All']['data'] ||= []
      service_project_names.each do |project_name|
        if @project_ids != :all
          month_data[month_year][project_name] ||= {}
          month_data[month_year][project_name]['data'] ||= []
        end
        if clients[project_name].present?
          clients[project_name].each do |row|
            # Only count clients who exited in this month
            next unless (beginning_of_month..end_of_month).include?(row[:search_end])
            month_data[month_year]['All']['data'] << row
            if @project_ids != :all
              month_data[month_year][project_name]['data'] << row
            end
          end
        end
      end
      month_data.each do |month_year, counts|
        counts.each do |project_name, project_data|
          data = project_data['data'].compact
          denominator = denominators[month_year].try(:[], project_name) || 0
          month_data[month_year][project_name]['denominator'] = denominator
          month_data[month_year][project_name]['numerator'] = data.count
          if denominator.zero? || data.count.zero?
            month_data[month_year][project_name]['percentage'] = 0
          else
            month_data[month_year][project_name]['percentage'] = ((data.count.to_f / denominator) * 100).round(2)
          end
        end
      end
    end

    return month_data
  end

  # Denominator: count exiting stabilization
  def percent_exiting_stabilization_to_housing_by_month
    columns = [:housed_date, :housing_exit, :residential_project, :destination, :client_id]

    denominators = {}
    in_stabilization.group_by{|m| m[:residential_project]}.map do |project_name, rows|
      months_for(start_date: start_date, end_date: end_date).each do |month_year|
        beginning_of_month = Date.parse "#{month_year} 01"
        end_of_month = beginning_of_month.end_of_month
        denominators[month_year] ||= {}
        denominators[month_year][project_name] = rows.count do |row|
          row.housing_exit.present? && row.housing_exit >= beginning_of_month && row.housing_exit <= end_of_month
        end
        denominators[month_year]['All'] ||= 0
        denominators[month_year]['All'] += denominators[month_year][project_name]
      end
    end

    client_scope = exiting_stabilization
    clients = client_scope.pluck(*columns).map do |row|
      Hash[columns.zip(row)]
    end.group_by do |row|
      row[:residential_project]
    end
    month_data = {}
    months_for(start_date: start_date, end_date: end_date).each do |month_year|
      beginning_of_month = Date.parse "#{month_year} 01"
      end_of_month = beginning_of_month.end_of_month

      month_data[month_year] ||= {}
      month_data[month_year]['All'] ||= {}
      month_data[month_year]['All']['data'] ||= []
      residential_project_names.each do |project_name|
        if @project_ids != :all
          month_data[month_year][project_name] ||= {}
          month_data[month_year][project_name]['data'] ||= []
        end
        if clients[project_name].present?
          clients[project_name].each do |row|
            # Only count clients who exited in this month to a permanent destination
            next unless HUD.permanent_destinations.include?(row[:destination])
            next unless (beginning_of_month..end_of_month).include?(row[:housing_exit])
            month_data[month_year]['All']['data'] << row
            if @project_ids != :all
              month_data[month_year][project_name]['data'] << row
            end
          end
        end
      end
      month_data.each do |month_year, counts|
        counts.each do |project_name, project_data|
          data = project_data['data'].compact
          denominator = denominators[month_year].try(:[], project_name) || 0
          month_data[month_year][project_name]['denominator'] = denominator
          month_data[month_year][project_name]['numerator'] = data.count
          if denominator.zero? || data.count.zero?
            month_data[month_year][project_name]['percentage'] = 0
          else
            month_data[month_year][project_name]['percentage'] = ((data.count.to_f / denominator) * 100).round(2)
          end
        end
      end
    end

    return month_data
  end

  # Denominator: count enrolled in either pre-placement or stabilization
  def percent_in_stabilization_by_month
    columns = [:search_start, :search_end, :service_project, :housed_date, :housing_exit, :residential_project, :client_id]

    denominators = {}
    enrolled_clients.group_by{|m| m[:residential_project]}.map do |project_name, rows|
      months_for(start_date: start_date, end_date: end_date).each do |month_year|
        beginning_of_month = Date.parse "#{month_year} 01"
        end_of_month = beginning_of_month.end_of_month
        denominators[month_year] ||= {}
        denominators[month_year][project_name] = rows.count do |row|
          row.search_start <= end_of_month && (row.housing_exit.blank? || row.housing_exit >= beginning_of_month)
        end
        denominators[month_year]['All'] ||= 0
        denominators[month_year]['All'] += denominators[month_year][project_name]
      end
    end

    client_scope = in_stabilization
    clients = client_scope.pluck(*columns).map do |row|
      Hash[columns.zip(row)]
    end.group_by do |row|
      row[:residential_project]
    end
    month_data = {}
    months_for(start_date: start_date, end_date: end_date).each do |month_year|
      beginning_of_month = Date.parse "#{month_year} 01"
      end_of_month = beginning_of_month.end_of_month

      month_data[month_year] ||= {}
      month_data[month_year]['All'] ||= {}
      month_data[month_year]['All']['data'] ||= []
      residential_project_names.each do |project_name|
        if @project_ids != :all
          month_data[month_year][project_name] ||= {}
          month_data[month_year][project_name]['data'] ||= []
        end
        if clients[project_name].present?
          clients[project_name].each do |row|
            # Only count clients enrolled during the month
            next unless row[:housed_date].present? && row[:housed_date] <= end_of_month && (row[:housing_exit].blank? || row[:housing_exit] >= beginning_of_month)
            month_data[month_year]['All']['data'] << row
            if @project_ids != :all
              month_data[month_year][project_name]['data'] << row
            end
          end
        end
      end
      month_data.each do |month_year, counts|
        counts.each do |project_name, project_data|
          data = project_data['data'].compact
          denominator = denominators[month_year].try(:[], project_name) || 0
          month_data[month_year][project_name]['denominator'] = denominator
          month_data[month_year][project_name]['numerator'] = data.count
          if denominator.zero? || data.count.zero?
            month_data[month_year][project_name]['percentage'] = 0
          else
            month_data[month_year][project_name]['percentage'] = ((data.count.to_f / denominator) * 100).round(2)
          end
        end
      end
    end

    return month_data
  end

  # average length of stay for clients who exited pre-placement in a given month
  def pre_placement_average_stay_by_month client_scope
    columns = [:search_start, :search_end, :service_project, :project_id, :housed_date]
    clients = client_scope.pluck(*columns).map do |row|
      Hash[columns.zip(row)]
    end.group_by do |row|
      row[:service_project]
    end
    month_data = {}
    months_for(start_date: start_date, end_date: end_date).each do |month_year|
      beginning_of_month = Date.parse "#{month_year} 01"
      end_of_month = beginning_of_month.end_of_month

      month_data[month_year] ||= {}
      month_data[month_year]['All'] ||= {}
      month_data[month_year]['All']['data'] ||= []
      service_project_names.each do |project_name|
        if @project_ids != :all
          month_data[month_year][project_name] ||= {}
          month_data[month_year][project_name]['data'] ||= []
        end
        if clients[project_name].blank?
          # comment this out to remove blanks from the average
          month_data[month_year]['All']['data'] << nil
          month_data[month_year][project_name]['data'] << nil if @project_ids != :all
        else
          # only include clients who exited this month
          clients[project_name].each do |row|
            next if row[:search_end].blank?
            next if row[:search_start] > end_of_month
            next if row[:search_end] < beginning_of_month || row[:search_end] > end_of_month
            next if row[:search_end].present? && row[:search_start] > row[:search_end]
            use_end_date = row[:search_end]
            month_data[month_year]['All']['data'] << (use_end_date - row[:search_start]).to_i
            if @project_ids != :all
              month_data[month_year][project_name]['data'] << (use_end_date - row[:search_start]).to_i
            end
          end
        end
      end
    end
    month_data.each do |month_year, counts|
      counts.each do |project_name, project_data|
        data = project_data['data'].compact
        month_data[month_year][project_name]['count'] = data.count
        if data.count.zero?
          month_data[month_year][project_name]['average'] = 0
        else
          month_data[month_year][project_name]['average'] = (data.sum.to_f / data.count).round(2)
        end
      end
    end

    return month_data
  end

  def stabilization_average_stay_by_month client_scope
    columns = [:housed_date, :housing_exit, :residential_project, :project_id]
    clients = client_scope.pluck(*columns).map do |row|
      Hash[columns.zip(row)]
    end.group_by do |row|
      row[:residential_project]
    end
    month_data = {}
    months_for(start_date: start_date, end_date: end_date).each do |month_year|
      beginning_of_month = Date.parse "#{month_year} 01"
      end_of_month = beginning_of_month.end_of_month
      month_data[month_year] ||= {}
      month_data[month_year]['All'] ||= {}
      month_data[month_year]['All']['data'] ||= []
      residential_project_names.each do |project_name|
        if @project_ids != :all
          month_data[month_year][project_name] ||= {}
          month_data[month_year][project_name]['data'] ||= []
        end
        if clients[project_name].blank?
          # comment this out to remove blanks from the average
          month_data[month_year]['All']['data'] << nil
          month_data[month_year][project_name]['data'] << nil if @project_ids != :all
        else
          clients[project_name].each do |row|
            next if row[:housing_exit].blank?
            next if row[:housed_date] >= end_of_month
            next if row[:housing_exit] < beginning_of_month || row[:housing_exit] > end_of_month
            next if row[:housing_exit].present? && row[:housed_date] > row[:housing_exit]
            use_end_date = row[:housing_exit]
            month_data[month_year]['All']['data'] << (use_end_date - row[:housed_date]).to_i
            if @project_ids != :all
              month_data[month_year][project_name]['data'] << (use_end_date - row[:housed_date]).to_i
            end
          end
        end
      end
    end
    month_data.each do |month_year, counts|
      counts.each do |project_name, project_data|
        data = project_data['data'].compact
        month_data[month_year][project_name]['count'] = data.count
        if data.count.zero?
          month_data[month_year][project_name]['average'] = 0
        else
          month_data[month_year][project_name]['average'] = (data.sum.to_f / data.count).round(2)
        end
      end
    end

    return month_data
  end

  def enrolled_clients
    housed_scope.
      enrolled(start_date: start_date, end_date: end_date).
      distinct
  end

  def pre_placement_clients
    housed_scope.
      enrolled_pre_placement(start_date: start_date, end_date: end_date).
      distinct
  end

  def stabilization_clients
    housed_scope.
      enrolled_stabilization(start_date: start_date, end_date: end_date).
      distinct
  end

  def bucket days
    length_of_time_buckets.select{ |k,_| k.include?(days) }&.values&.first
  end

  def length_of_time_buckets
    @length_of_time_buckets ||= {
      (0..7) => 'Less than 1 week',
      (8..30) => '1 week to one month',
      (31..91) => '1 month to 3 months',
      (92..182) => '3 months to 6 months',
      (183..364) => '6 months to 1 year',
      (365..728) => '1 year to 2 years',
      (729..Float::INFINITY) => '2 years or more',
    }
  end

  def default_support_columns
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_returns_after_exit
    {
      exit_date: _('Housing Exit'),
      return_date: _('Date of Return'),
      days_to_return: _('Days to Return'),
    }
  end

  def columns_for_percent_exiting_pre_placement
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      housed_date: _('Date Housed'),
    }
  end

  def columns_for_percent_in_stabilization
    {
      service_project: _('Pre-Placement Project'),
      search_start: _('Search Start'),
      search_end: _('Search End'),
      residential_project: _('Stabilization Project'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  def columns_for_percent_exiting_stabilization
    {
      residential_project: _('Stabilization Project'),
      destination: _('Destination'),
      housed_date: _('Date Housed'),
      housing_exit: _('Housing Exit'),
    }
  end

  # returns array of clients with id, first name, last name who match the metric
  def support_for metric, params=nil
    columns = default_support_columns
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
      if params[:selected_project] == 'All'
        project_name = service_project_names
      else
        project_name = valid_project_name(params[:selected_project])
      end
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement_exit_to_stabilization.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :pre_placement_no_stabilization_exit
      if params[:selected_project] == 'All'
        project_name = service_project_names
      else
        project_name = valid_project_name(params[:selected_project])
      end
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement_exit_no_stabilization.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :pre_placement_any_exit
      if params[:selected_project] == 'All'
        project_name = service_project_names
      else
        project_name = valid_project_name(params[:selected_project])
      end
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = leavers_pre_placement.where(service_project: project_name).
        enrolled_pre_placement(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :time_in_stabilization
      if params[:selected_project] == 'All'
        project_name = residential_project_names
      else
        project_name = valid_project_name(params[:selected_project])
      end
      start_date = "#{params[:month]} 01".to_date
      end_date = start_date.end_of_month
      rows = exiting_stabilization.where(residential_project: project_name).
        exiting_stabilization(start_date: start_date, end_date: end_date).
        pluck(*([:client_id] + columns.keys))
    when :return_after_exit_to_ph
      columns = columns_for_returns_after_exit
      bucket = length_of_time_buckets.values.detect do |label|
        params[:bucket] == label
      end
      rows = returns_to_shelter_after_ph.select do |_, row|
        row[:bucket] == bucket
      end.map do |_, row|
        [
          row[:client_id],
          row[:exit_date],
          row[:entry_date], # actually return date
          row[:days_to_return],
        ]
      end
    when :return_after_exit_to_any
      columns = columns_for_returns_after_exit
      bucket = length_of_time_buckets.values.detect do |label|
        params[:bucket] == label
      end
      rows = returns_to_shelter_after_exit.select do |_, row|
        row[:bucket] == bucket
      end.map do |_, row|
        [
          row[:client_id],
          row[:exit_date],
          row[:entry_date], # actually return date
          row[:days_to_return],
        ]
      end
    when :percent_exiting_pre_placement
      columns = columns_for_percent_exiting_pre_placement
      month = params[:month]
      if params[:selected_project] == 'All'
        project_name = 'All'
      else
        project_name = valid_project_name(params[:selected_project])
      end
      support = percent_exiting_pre_placement_data[:support][month][project_name]['data']
      rows = support.map do |row|
        [
          row[:client_id],
          row[:service_project],
          row[:search_start],
          row[:search_end],
          row[:housed_date],
        ]
      end
    when :percent_in_stabilization
      columns = columns_for_percent_in_stabilization
      month = params[:month]
      if params[:selected_project] == 'All'
        project_name = 'All'
      else
        project_name = valid_project_name(params[:selected_project])
      end
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
      columns = columns_for_percent_exiting_stabilization
      month = params[:month]
      if params[:selected_project] == 'All'
        project_name = 'All'
      else
        project_name = valid_project_name(params[:selected_project])
      end
      support = percent_exiting_stabilization_data[:support][month][project_name]['data']
      rows = support.map do |row|
        [
          row[:client_id],
          row[:residential_project],
          HUD.destination(row[:destination]),
          row[:housed_date],
          row[:housing_exit],
        ]
      end
    when :destination
      columns = {
        residential_project: _('Stabilization Project'),
        destination: _('Destination'),
        housed_date: _('Date Housed'),
        housing_exit: _('Housing Exit'),
      }
      support = destinations[:support][params[:destination]].try(:[], :support)
      rows = support.map do |row|
        [
          row[:client_id],
          row[:residential_project],
          HUD.destination(row[:destination]),
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

  def valid_project_name name
    (service_project_names + residential_project_names).detect{|m| m == name}
  end

  # selected projects
  def projects
    @projects ||= project_source.where(id: @project_ids)
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def client_source
    GrdaWarehouse::Hud::Client
  end

  def housed_source
    Reporting::Housed.rrh
  end

  def housed_scope
    scope = if ! all_projects
      housed_source.where(project_id: @project_ids)
    else
      housed_source.all
    end
    scope = scope.
      send(@subpopulation).
      send(@household_type)

    scope = scope.where(race: @race&.to_s) unless @race == :current_scope
    scope = scope.where(ethnicity: @ethnicity&.to_s&.to_i) unless @ethnicity == :current_scope
    scope = scope.where(gender: @gender&.to_s&.to_i) unless @gender == :current_scope
    scope = scope.where(veteran_status: @veteran_status&.to_s&.to_i) unless @veteran_status == :current_scope

    return scope
  end

  def all_projects
    @project_ids == :all
  end

  def ho_t
    housed_source.arel_table
  end

  class Support < OpenStruct

    # rows must contain client_id in the first column
    # clients array must be in the format [[id, FirstName, LastName]]
    def initialize clients:, rows:, headers:
      @clients = clients.index_by(&:first)
      @rows = rows
      @headers = client_headers + headers
    end

    def client_headers
      [
        'Warehouse ID',
        'First Name',
        'Last Name'
      ]
    end

    def headers
      @headers
    end

    # return an array of arrays where the first three columns are
    # client_id, FirstName, LastName
    # and the remaining columns are from the rows array which should match the order of the headers
    def support_rows
      @rows.map do |row|
        client_id = row.first
        client = @clients[client_id]
        first_name = client[1]
        last_name = client[2]
        Hash[@headers.zip([client_id, first_name, last_name] + row.drop(1))]
      end
    end
  end
end