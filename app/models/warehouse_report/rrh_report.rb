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
      pluck(:search_start).map do |entry_date| 
        [entry_date, Date.today] 
      end
  end

  def stayers_average_days_in_pre_placement
    days = stayers_days_in_pre_placement.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
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
      (exit_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / leavers_days_in_stabilization.count).round
  end

  def stayers_days_in_stabilization
    @stayers_days_in_stabilization ||= housed_scope.
      stayers_stabilization(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:housed_date).map do |entry_date| 
        [entry_date, Date.today] 
      end
  end

  def stayers_average_days_in_stabilization
    days = stayers_days_in_stabilization.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
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
      pluck(:search_start).map do |entry_date| 
        [entry_date, Date.today] 
      end
  end

  def stayers_average_days
    days = stayers_days.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
    end.sum
    return days if days == 0
    (days.to_f / stayers_days.count).round
  end


  def destinations
    @destinations ||= housed_scope.
      leavers(start_date: start_date, end_date: end_date).
      where(ho_t[:destination].not_eq(nil)).
      group(ho_t[:destination].to_sql).
      count(ho_t[:destination].to_sql).map do |id, count|
        [ 
          id,
          {
            destination_id: id,
            destination: HUD.destination(id),
            count: count,
          },
        ]
      end.to_h
  end

  # returns to shelter after exiting to permanent housing
  def returns_to_shelter
    leavers_with_date = housed_scope.
      leavers(start_date: start_date, end_date: end_date).
      ph_destinations.
      distinct.
      pluck(:client_id, :housing_exit).to_h
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

  def housed_source
    Reporting::Housed
  end

  def housed_scope
    if @project_id != :all
      housed_source.where(project_id: @project_id).send(@subpopulation).send(@household_type)
    else
      housed_source.all.send(@subpopulation).send(@household_type)
    end
  end

  def ho_t
    housed_source.arel_table
  end

end