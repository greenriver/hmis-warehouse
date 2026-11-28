###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Per-cohort configure access: existing participants with a configure role become
# managers of their cohorts. Runs here so it finishes before the new code serves requests.
class BackfillCohortManagers < ActiveRecord::Migration[7.2]
  def up
    GrdaWarehouse::Tasks::BackfillCohortManagers.new.run!
  end

  def down
  end
end
