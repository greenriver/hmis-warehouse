###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

desc "Install needed node packages"
task :npm_install, [] => [] do |t, args|
  on roles(:web, :job, :app, :cron) do
    within release_path do
      # ignore engine check because we're using node 12 here
      execute :yarn, :install, '--ignore-engines'
    end
  end
end
