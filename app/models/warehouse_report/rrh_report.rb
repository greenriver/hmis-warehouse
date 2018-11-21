class WarehouseReport::RrhReport
  include ArelHelper

  attr_accessor :project_id, :start_date, :end_date
  def initialize project_id:, start_date:, end_date:
    @project_id = project_id
    @start_date = start_date
    @end_date = end_date
  end

  def entering_pre_placement
    pre_placement_project.entering_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def exiting_pre_placement
    pre_placement_project.exiting_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def entering_stabilization
    stabilization_project.entering_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
  end

  def exiting_stabilization
    stabilization_project.exiting_clients(start_date: start_date, end_date: end_date).
      distinct.
      pluck(:client_id)
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

  # selected project
  def project
    @project ||= project_source.find(@project_id)
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end


end