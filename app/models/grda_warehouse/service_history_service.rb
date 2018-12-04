class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  include ServiceHistoryServiceConcern

  belongs_to :service_history_enrollment, inverse_of: :service_history_services
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

  scope :hud_project_type, -> (project_types) do
    in_project_type(project_types)
  end

  scope :permanent_housing, -> do
    project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten
    in_project_type(project_types)
  end

  scope :homeless_sheltered, -> do
    in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_SHELTERED_PROJECT_TYPES)
  end
  scope :homeless_unsheltered, -> do
    in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_UNSHELTERED_PROJECT_TYPES)
  end

  scope :in_project_type, -> (project_types) do
    where(project_type_column => project_types)
  end


  scope :homeless_only, -> (start_date:, end_date:) do
    # CHRONIC_PROJECT_TYPES
    # HOMELESS_PROJECT_TYPES
    homeless_project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - homeless_project_types

    where(
      project_type: homeless_project_types,
      date: (start_date..end_date)
    ).
    where(
      GrdaWarehouse::ServiceHistoryService.
        where(shs_t[:client_id].eq(arel_table[:client_id])).
        where(date: (start_date..end_date)).
        where.not(project_type: non_homeless).
        exists
    )
  end

  scope :literally_homeless_only, -> (start_date:, end_date:) do
    homeless_project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - homeless_project_types

    where(
      project_type: homeless_project_types,
      date: (start_date..end_date)
    ).
    where(
      GrdaWarehouse::ServiceHistoryService.
        where(shs_t[:client_id].eq(arel_table[:client_id])).
        where(date: (start_date..end_date)).
        where.not(project_type: non_homeless).
        exists
    )
  end

  scope :youth, -> do
    where(age: (18..24))
  end

  scope :children, -> do
    where(age: (0...18))
  end

  scope :adult, -> do
    where(age: (18..Float::INFINITY))
  end

  def self.project_type_column
    :project_type
  end

  def self.sub_tables
    table_years.map do |year|
      [year, "service_history_services_#{year}"]
    end.reverse.to_h
  end

  def self.remainder_table
    :service_history_services_remainder
  end

  def self.table_years
    (2000..2050)
  end

  def self.parent_table
    :service_history_services
  end
end