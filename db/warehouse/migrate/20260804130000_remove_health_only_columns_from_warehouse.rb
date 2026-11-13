###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# `configs`, `report_definitions`, and `hmis_assessments` live in the warehouse
# database (see db/warehouse_structure.sql), not the primary database, so this
# migration is separate from the `roles` column removal in
# db/migrate/20260804130000_remove_health_only_columns.rb.
class RemoveHealthOnlyColumnsFromWarehouse < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_column :configs, :healthcare_available
      remove_column :report_definitions, :health
      remove_column :hmis_assessments, :health
      remove_column :hmis_assessments, :health_case_note
      remove_column :hmis_assessments, :health_has_qualifying_activities
    end
  end

  def down
    safety_assured do
      add_column :hmis_assessments, :health_has_qualifying_activities, :boolean, default: false
      add_column :hmis_assessments, :health_case_note, :boolean, default: false
      add_column :hmis_assessments, :health, :boolean, default: false, null: false
      add_column :report_definitions, :health, :boolean, default: false
      add_column :configs, :healthcare_available, :boolean, default: false, null: false
    end
  end
end
