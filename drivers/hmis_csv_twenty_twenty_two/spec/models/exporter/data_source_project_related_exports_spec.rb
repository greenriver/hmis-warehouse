###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'
require_relative './multi_project_tests'
require_relative './multi_enrollment_tests'

def project_test_type
  'data source-based'
end

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data
    @project_class = HmisCsvTwentyTwentyTwo::Exporter::Project
    @enrollment_class = HmisCsvTwentyTwentyTwo::Exporter::Enrollment
    @client_class = HmisCsvTwentyTwentyTwo::Exporter::Client
    @involved_project_ids = @data_source.project_ids.first(3)
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
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

  include_context '2022 multi-project tests'
  include_context '2022 multi-enrollment tests'
end
