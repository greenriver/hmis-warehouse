###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis_supplemental:import
desc 'Import supplemental data for every sync-enabled data set'
task import: [:environment, 'log:info_to_stdout'] do
  HmisSupplemental::DataSet.where(sync_enabled: true).order(:id).each do |data_set|
    HmisSupplemental::ImportJob.new.perform(data_set_id: data_set.id)
  end
end
