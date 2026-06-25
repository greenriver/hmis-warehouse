###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :deploy do
  desc "Notice end of deployment tasks"
  task :mark_deployment_id, [] => [:environment] do |t, args|
    Rails.cache.write('registered-deployment-id', ENV['DEPLOYMENT_ID'])
  end
end
