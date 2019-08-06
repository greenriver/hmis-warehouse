###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  include ServiceHistoryServiceConcern

  belongs_to :service_history_enrollment, inverse_of: :service_history_services
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  has_one :enrollment, through: :service_history_enrollment

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

  scope :homeless_between, -> (start_date:, end_date:) do
    homeless(chronic_types_only: false).where(date: (start_date..end_date))
end

  scope :literally_homeless_between, -> (start_date:, end_date:) do
    homeless(chronic_types_only: true).where(date: (start_date..end_date))
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