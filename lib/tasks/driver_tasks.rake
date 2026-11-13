###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Load driver rake tasks, each namespaced under driver:<driver_name>:
# Replicates what the rails_drivers gem's Railtie did in its rake_tasks block.
Dir['drivers/*/lib/tasks/**/*.rake'].each do |driver_rake_file|
  driver_name = driver_rake_file.match(/^drivers\/(\w+)\//)[1]

  namespace(:driver) do
    namespace(driver_name) do
      load driver_rake_file
    end
  end
end
