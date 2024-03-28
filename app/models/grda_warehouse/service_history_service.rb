###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = GrdaWarehouse::ServiceHistoryService
#
# ServiceHistoryService flatten HUD Service and related records to serve reporting needs. These records are generated
# automatically. ServiceHistoryService records records are a superset of HUD Services, they include "synthetic" services
# that are implied but not recorded, such as bed-nights at EE projects.
class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  include ServiceHistoryServiceConcern

  belongs_to :service_history_enrollment, primary_key: [:id, :client_id], foreign_key: [:service_history_enrollment_id, :client_id], inverse_of: :service_history_services, optional: true
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  has_one :enrollment, through: :service_history_enrollment

  scope :service_between, ->(start_date:, end_date:, service_scope: :current_scope) do
    if service_scope.is_a?(ActiveRecord::Relation)
      merge(service_scope).where(date: start_date..end_date)
    else
      (send(service_scope) || all).
        where(date: start_date..end_date)
    end
  end

  scope :on_date, ->(date, service_scope: :current_scope) do
    service_between(start_date: date, end_date: date, service_scope: service_scope)
  end

  scope :hud_project_type, ->(project_types) do
    in_project_type(project_types)
  end

  scope :permanent_housing, -> do
    in_project_type(HudUtility2024.residential_project_type_numbers_by_code[:ph])
  end

  scope :transitional_housing, -> do
    in_project_type(HudUtility2024.residential_project_type_numbers_by_code[:th])
  end

  scope :homeless_sheltered, -> do
    in_project_type(HudUtility2024.homeless_sheltered_project_types)
  end
  scope :homeless_unsheltered, -> do
    in_project_type(HudUtility2024.homeless_unsheltered_project_types)
  end

  scope :homeless_between, ->(start_date:, end_date:) do
    homeless(chronic_types_only: false).where(date: (start_date..end_date))
  end

  scope :literally_homeless_between, ->(start_date:, end_date:) do
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

  scope :aged, ->(range) do
    where(age: range)
  end

  scope :unknown_age, -> do
    where(age: nil).or(where(age: 105..Float::INFINITY)).or(where(age: -Float::INFINITY..-1))
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

  def self.view_column_names
    column_names - [
      'service_type',
      'homeless',
      'literally_homeless',
    ]
  end
end
