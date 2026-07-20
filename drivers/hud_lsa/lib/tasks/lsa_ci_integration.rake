###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Loaded under the driver:hud_lsa namespace by lib/tasks/driver_tasks.rake, so
# this runs as: rails driver:hud_lsa:ci_integration_test
desc 'Run the FY2026 LSA end-to-end against SQL Server and compare output to fixtures'
task ci_integration_test: :environment do
  scopes = [:lsa, :hic]
  passed = scopes.map do |scope|
    HudLsa::Fy2026::CiIntegrationCheck.run!(scope: scope)
  end

  if passed.all?
    puts 'LSA CI integration test PASSED'
  else
    failed = scopes.zip(passed).reject { |_scope, ok| ok }.map(&:first)
    abort("LSA CI integration test FAILED for: #{failed.join(', ')}")
  end
end
