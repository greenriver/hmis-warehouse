###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe LongitudinalSpm::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:user) { create :user }

  describe 'default report' do
    it 'running the report with default values does not fail' do
      report = LongitudinalSpm::Report.new(
        user_id: user.id,
      )
      expect { report.run_and_save! }.not_to raise_error
    end
  end
end
