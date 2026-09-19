###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :deploy do
  desc "Notice end of deployment tasks"
  # The ECS deploy tooling used to inject a per-deployment DEPLOYMENT_ID. Nothing sets
  # it under Kubernetes, so we key off the revision baked into the image instead: it
  # changes with every deployment and is identical in the deploy-tasks and app pods.
  # system_status/details compares this cached value against the running pod's revision
  # to show whether deploy tasks have finished for the code that's serving.
  task :mark_deployment_id, [] => [:environment] do |t, args|
    Rails.cache.write('registered-deployment-id', Git.revision)
  end
end
