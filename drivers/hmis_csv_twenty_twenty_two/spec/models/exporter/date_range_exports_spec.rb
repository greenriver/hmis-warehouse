###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'
require_relative './multi_enrollment_tests'

def project_test_type
  'enrollment date-based'
end

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  # Setup such that there are more than 3 of each item, but three fall within the date range
  before(:all) do
    cleanup_test_environment
    setup_data

    # Move 2 enrollments out of the range
    @enrollments.sort_by(&:id).last(2).each { |m| m.update(EntryDate: 2.days.ago) }
    # Move 3 exits into the range
    @exits.sort_by(&:id).first(3).each { |m| m.update(ExitDate: 2.weeks.ago) }
    # Move 3 assessments into range
    @assessments.sort_by(&:id).first(3).each { |m| m.update(AssessmentDate: 2.weeks.ago) }

    @involved_project_ids = @projects.map(&:id)
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 3.week.ago.to_date,
      end_date: 1.weeks.ago.to_date,
      projects: @involved_project_ids,
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
  end

  include_context '2022 multi-enrollment tests'
end
