###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'
require_relative './single_project_tests'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [ExportHelper2026.projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2026.user.id,
    )
    ExportHelper2026.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2026.cleanup
  end

  include_context '2026 single-project tests'
end
