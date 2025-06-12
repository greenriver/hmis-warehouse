###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2024'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2024.setup_data

    # Set up the rounding test
    ExportHelper2024.income_benefits.each do |ib|
      ib.update(TotalMonthlyIncome: 0.009)
    end

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
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

  it "IncomeBenefits.TotalMonthlyIncome should be rounded to '0.01'" do
    csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.income_benefit_class), headers: true)
    expect(csv.first['TotalMonthlyIncome']).to eq '0.01'
  end
end
