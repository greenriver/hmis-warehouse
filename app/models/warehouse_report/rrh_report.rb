# dev projects -- with affiliation: 61; single RRH: 44

class WarehouseReport::RrhReport
  include ArelHelper

  attr_accessor :project_id, :start_date, :end_date, :subpopulation, :household_type
  def initialize project_id:, start_date:, end_date:, subpopulation:, household_type:
    @project_id = project_id
    @start_date = start_date
    @end_date = end_date
    @subpopulation = Reporting::Housed.subpopulation(subpopulation)
    @household_type = Reporting::Housed.household_type(household_type)
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

  # newly enrolled during date range
  def entering_pre_placement
    housed_scope.entering_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  # exited pre-placement during date range if two projects
  # received move-in-date if one project
  def exiting_pre_placement
    housed_scope.exiting_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def entering_stabilization
    housed_scope.entering_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def exiting_stabilization
    housed_scope.exiting_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def leavers_days_in_pre_placement
    @leavers_days_in_pre_placement ||= housed_scope.
      leavers_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:search_start, :search_end)
  end

  def leavers_average_days_in_pre_placement
    days = leavers_days_in_pre_placement.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_days_in_pre_placement.count).round
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
      @destinations = {
        'returned to shelter' => {},
        'exited to other institution' => {},
        'successful exit to PH' => {},
        'exited to temporary destination' => {},
        'unknown outcome' => {},
      }
      housed_scope.
        exiting_stabilization(start_date: start_date, end_date: end_date).
        where(ho_t[:destination].not_eq(nil)).
        distinct.
        pluck(:client_id, :destination).map do |client_id, dest_id|
          destination = destination_bucket(client_id, dest_id)
          @destinations[destination][:destination] ||= destination_bucket(client_id, dest_id)
          @destinations[destination][:count] ||= 0
          @destinations[destination][:client_ids] ||= Set.new
          # Only count each client once per bucket
          @destinations[destination][:count] += 1 unless @destinations[destination][:client_ids].include?(client_id)
          @destinations[destination][:client_ids] << client_id
        end
      @destinations.delete_if{|_,v| v == {} }
    end
  end

  def destination_bucket client_id, dest_id
    return 'returned to shelter' if returns_to_shelter.keys.include?(client_id)
    return 'exited to other institution' if HUD.institutional_destinations.include?(dest_id)
    return 'successful exit to PH' if HUD.permanent_destinations.include?(dest_id)
    return 'exited to temporary destination' if HUD.temporary_destinations.include?(dest_id)
    return 'unknown outcome'
  end

  def ph_leavers
    housed_scope.
      exiting_stabilization(start_date: start_date, end_date: end_date).
      ph_destinations.
      distinct
  end

  # returns to shelter after exiting to permanent housing
  def returns_to_shelter
    @returns_to_shelter ||= begin
      leavers_with_date = ph_leavers.pluck(:client_id, :housing_exit).to_h
      return {} unless leavers_with_date.present?
      returner_ids = Reporting::Return.where(client_id: leavers_with_date.keys).distinct.pluck(:client_id)
      rr_t = Reporting::Return.arel_table
      returns = {}
      returner_ids.each do |id|
        # find the first start date after the exit to PH
        first_return = Reporting::Return.where(client_id: id).
          where(rr_t[:first_date_in_program].gt(leavers_with_date[id])).
          minimum(:first_date_in_program)
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

  def percent_returns_to_shelter
    return 0 unless ph_leavers.exists?
    (returns_to_shelter.uniq.count.to_f/ph_leavers.select(:client_id).count * 100).round(2)
  end

  def bucketed_returns
    @bucketed_returns ||= {}
    grouped_returns = returns_to_shelter.values.group_by{|m| m[:bucket]}
    length_of_time_buckets.each do |_, bucket_text|
      if grouped_returns[bucket_text].present?
        @bucketed_returns[bucket_text] = grouped_returns[bucket_text].count
      end
    end
    return @bucketed_returns.to_a
  end

  def returns_for_chart
    {
      labels: bucketed_returns.map(&:first),
      data: [['Client count'] + bucketed_returns.map(&:last)],
    }
  end

  # Supporting methods
  
  def enrolled_client_ids
    housed_scope.
      enrolled(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def pre_placement_client_ids
    housed_scope.
      enrolled_pre_placement(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def stabilization_client_ids
    housed_scope.
      enrolled_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
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
      (183..364) => '3 months to 1 year',
      (365..728) => '1 year to 2 years',
      (729..Float::INFINITY) => '2 years or more',
    }
  end

  # returns array of clients with id, first name, last name who match the metric
  def support_for metric
    case metric
    when :enrolled_clients
      client_ids = enrolled_client_ids
    when :enrolled_in_pre_placement
      client_ids = pre_placement_client_ids
    when :enrolled_in_stabilization
      client_ids = stabilization_client_ids
    when :entering_pre_placement
      client_ids = entering_pre_placement
    when :exiting_pre_placement
      client_ids = exiting_pre_placement
    when :entering_stabilization
      client_ids = entering_stabilization
    when :exiting_stabilization
      client_ids = exiting_stabilization
    end
    client_source.where(id: client_ids).
      order(:LastName, :FirstName).
      pluck(:id, :FirstName, :LastName)
  end

  # See if this project has a residential_project, if it does, use that ID
  # NOTE: the spec supports the possibility of more than one affiliation
  # we're assuming one for now 
  def stabilization_project
    @stabilization_project ||= if project.residential_projects.exists?
      project.residential_projects.first
    else
      project
    end
  end

  def pre_placement_project
    @pre_placement_project ||= if project.affiliated_projects.exists?
      project.affiliated_projects.first
    else
      project
    end
  end

  def two_project_setup?
    @two_project_setup ||= stabilization_project.id != pre_placement_project.id
  end

  # selected project
  def project
    @project ||= project_source.find(@project_id)
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def client_source
    GrdaWarehouse::Hud::Client
  end

  def housed_source
    Reporting::Housed
  end

  def housed_scope
    if ! all_projects
      housed_source.where(project_id: @project_id).send(@subpopulation).send(@household_type)
    else
      housed_source.all.send(@subpopulation).send(@household_type)
    end
  end

  def all_projects
    @project_id == :all
  end

  def ho_t
    housed_source.arel_table
  end

end