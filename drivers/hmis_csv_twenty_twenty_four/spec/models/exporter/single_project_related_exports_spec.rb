###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'
require_relative './single_project_tests'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
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

  include_context '2024 single-project tests'
end
