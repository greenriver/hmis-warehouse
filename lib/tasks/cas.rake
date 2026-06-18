###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :cas do
  desc 'Sync clients flagged with sync_to_cas with CAS'
  task :sync, [:replace_all] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
  end
end
