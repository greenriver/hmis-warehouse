###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'
require_relative './multi_project_tests'
require_relative './multi_enrollment_tests'

def project_test_type
  'project group-based'
end

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    @project_group = FactoryBot.create :project_group, name: 'P Group', options: ::Filters::HudFilterBase.new(user_id: ExportHelper2026.user.id).update(project_ids: ExportHelper2026.projects.first(3).map(&:id)).to_h, projects: ExportHelper2026.projects.first(3)
    @involved_project_ids = @project_group.project_ids
    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: @involved_project_ids,
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

  include_context '2026 multi-project tests'
  include_context '2026 multi-enrollment tests'
end
