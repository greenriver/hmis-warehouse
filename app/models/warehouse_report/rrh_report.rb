# dev projects -- with affiliation: 11; single RRH: 2
class WarehouseReport::RrhReport
  include ArelHelper

  attr_accessor :project_id, :start_date, :end_date
  def initialize project_id:, start_date:, end_date:
    @project_id = project_id
    @start_date = start_date
    @end_date = end_date
  end

  # newly enrolled during date range
  def entering_pre_placement
    pre_placement_project.entering_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  # exited pre-placement during date range if two projects
  # received move-in-date if one project
  def exiting_pre_placement
    exiting_scope = if two_project_setup?
      pre_placement_project.
        exiting_clients(start_date: start_date, end_date: end_date)
    else
      pre_placement_project.
        housed_between(start_date: start_date, end_date: end_date)
    end
    exiting_scope.
      distinct.
      pluck(:client_id)
  end

  # entered stabilization during date range if two projects
  # received move-in-date if one project
  def entering_stabilization
    entering_scope = if two_project_setup?
      stabilization_project.
        entering_clients(start_date: start_date, end_date: end_date)
    else
      stabilization_project.
        housed_between(start_date: start_date, end_date: end_date)
    end
    entering_scope.distinct.
      pluck(:client_id)
  end

  def exiting_stabilization
    stabilization_project.
      exiting_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def days_in_pre_placement
    @days_in_pre_placement ||= if two_project_setup?
      pre_placement_project.
        exiting_clients(start_date: start_date, end_date: end_date).
        pluck(she_t[:first_date_in_program].to_sql, she_t[:last_date_in_program].to_sql)
    else
      pre_placement_project.
        housed_between(start_date: start_date, end_date: end_date).
        pluck(she_t[:first_date_in_program].to_sql, e_t[:MoveInDate].to_sql)
    end
  end

  def average_days_in_pre_placement
    days = days_in_pre_placement.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
    end.sum
    (days.to_f / days_in_pre_placement.count).round
  end

  def days_in_stabilization
    @days_in_stabilization ||= if two_project_setup?
      stabilization_project.
        exiting_clients(start_date: start_date, end_date: end_date).
        pluck(she_t[:first_date_in_program].to_sql, she_t[:last_date_in_program].to_sql)
    else
      stabilization_project.
        exiting_clients(start_date: start_date, end_date: end_date).
        joins(:enrollment).
        merge(GrdaWarehouse::Hud::Enrollment.where.not(MoveInDate: nil)).
        pluck(e_t[:MoveInDate].to_sql, she_t[:last_date_in_program].to_sql)
    end
  end

  def average_days_in_stabilization
    days = days_in_stabilization.map do |entry_date, exit_date| 
      (exit_date - entry_date).to_i
    end.sum
    (days.to_f / days_in_stabilization.count).round
  end


  def enrolled_client_ids
    client_ids = Set.new
    client_ids += stabilization_client_ids
    client_ids += pre_placement_client_ids
    client_ids
  end

  def pre_placement_client_ids
    pre_placement_project.enrolled_scope(start_date: start_date, end_date: end_date).
      distinct.pluck(:client_id)
  end

  def stabilization_client_ids
    stabilization_project.enrolled_scope(start_date: start_date, end_date: end_date).
      distinct.pluck(:client_id)
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


end