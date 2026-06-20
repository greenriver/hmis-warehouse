###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  def self.table_name_prefix
    'hmis_simulation_'
  end

  # The simulation fabricates HUD records, so it must never touch a production
  # database. This is the real invariant; it's enforced at the mutation boundary
  # (Engine#run, Bootstrapper#run!) so every caller — rake task, job, or console —
  # is covered, not just the path that happens to check first.
  def self.ensure_not_production!
    raise 'Refusing to generate HMIS simulation data in production' if Rails.env.production?
  end
end
