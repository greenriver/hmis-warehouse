###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# These jobs moved their instrument_as_maintenance_task call inside their advisory lock, so that a
# run which never gets the lock records no completion and the task alerts.
#
class RenameMaintenanceTasksWithLockScopedInstrumentation < ActiveRecord::Migration[8.1]
  RENAMES = {
    'GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask#perform' => 'GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask: cleanup old queries',
    'GrdaWarehouse::Tasks::SyncAnalysisDataTask#perform' => 'GrdaWarehouse::Tasks::SyncAnalysisDataTask: sync app users',
    'Hmis::ActivityLogProcessorJob#perform' => 'Hmis::ActivityLogProcessorJob: process activity logs',
    'Hmis::AutoExitJob#perform' => 'Hmis::AutoExitJob: auto exit',
    'Hmis::Ce::ProcessClientsJob#perform' => 'Hmis::Ce::ProcessClientsJob: process dirty clients',
    'Hmis::Ce::ProcessPoolsJob#perform' => 'Hmis::Ce::ProcessPoolsJob: process dirty pools',
    'HmisExternalApis::ConsumeExternalFormSubmissionsJob#perform' => 'HmisExternalApis::ConsumeExternalFormSubmissionsJob: consume submissions',
    'PruneDocumentExportsJob#perform' => 'PruneDocumentExportsJob: prune expired exports',
  }.freeze

  def up
    RENAMES.each { |from, to| rename_task(from, to) }
  end

  def down
    RENAMES.each { |from, to| rename_task(to, from) }
  end

  private

  # name is uniquely indexed, and a rolling deploy can run a job under its new name before this
  # migration lands, creating that row itself. Skip rather than fail the deploy; the row left
  # behind under the old name is then just the orphan we already had.
  def rename_task(from, to)
    safety_assured do
      execute(<<~SQL)
        UPDATE system_maintenance_tasks
        SET name = #{quote(to)}, updated_at = NOW()
        WHERE name = #{quote(from)}
          AND NOT EXISTS (SELECT 1 FROM system_maintenance_tasks existing WHERE existing.name = #{quote(to)})
      SQL
    end
  end

  def quote(value)
    connection.quote(value)
  end
end
