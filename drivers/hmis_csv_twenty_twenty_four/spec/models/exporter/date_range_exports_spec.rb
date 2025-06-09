###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2024'
require_relative './multi_enrollment_tests'

def project_test_type
  'enrollment date-based'
end

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  # Setup such that there are more than 3 of each item, but three fall within the date range
  before(:all) do
    cleanup_test_environment
    ExportHelper2024.setup_data

    # Move 2 enrollments out of the range
    ExportHelper2024.enrollments.sort_by(&:id).last(2).each { |m| m.update(EntryDate: 2.days.ago) }
    # Move 3 exits into the range
    ExportHelper2024.exits.sort_by(&:id).first(3).each { |m| m.update(ExitDate: 2.weeks.ago) }
    # Move 3 assessments into range
    ExportHelper2024.assessments.sort_by(&:id).first(3).each { |m| m.update(AssessmentDate: 2.weeks.ago) }

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 3.week.ago.to_date,
      end_date: 1.weeks.ago.to_date,
      projects: ExportHelper2024.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2024.user.id,
    )
    ExportHelper2024.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2024.cleanup
  end

  include_context '2024 multi-enrollment tests'
end
