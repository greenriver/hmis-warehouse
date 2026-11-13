###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis:auto_exit
desc 'Auto-exit HMIS enrollments in projects configured for it'
task auto_exit: [:environment, 'log:info_to_stdout'] do
  next unless HmisEnforcement.hmis_enabled? && GrdaWarehouse::DataSource.hmis.exists?

  Hmis::AutoExitJob.new.perform
end
