###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data

    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: @projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )

    @income_benefits.each do |ib|
      ib.update(total_monthly_income: 0.009)
    end

    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
  end

  it "IncomeBenefits.TotalMonthlyIncome should be rounded to '0.01'" do
    csv = CSV.read(csv_file_path(@income_benefit_class, exporter: @exporter), headers: true)
    expect(csv.first['TotalMonthlyIncome']).to eq '0.01'
  end
end
