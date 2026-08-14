###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fix Missing Monthly Total Income', type: :model do
  def income_benefit(id)
    GrdaWarehouse::Hud::IncomeBenefit.find_by(IncomeBenefitsID: id)
  end

  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 15) do
        setup(with_cleanup: false)
      end
    end

    it 'leaves the missing total blank' do
      expect(income_benefit('IB-1').TotalMonthlyIncome).to be_blank
    end

    it 'does not alter the canary records' do
      expect(income_benefit('IB-2').TotalMonthlyIncome.to_i).to eq(100)
      expect(income_benefit('IB-3').TotalMonthlyIncome).to be_blank
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 15) do
        setup(with_cleanup: true)
      end
    end

    it 'fills in the missing total by summing income sources' do
      expect(income_benefit('IB-1').TotalMonthlyIncome.to_i).to eq(100)
    end

    it 'does not alter the canary records' do
      # already had a total, so it is not "missing" and is left as-is
      expect(income_benefit('IB-2').TotalMonthlyIncome.to_i).to eq(100)
      # indicates no income, so it is left alone
      expect(income_benefit('IB-3').TotalMonthlyIncome).to be_blank
    end

    it 'refreshes the staging record source_hash so change-detection stays consistent' do
      # The staging (importer) row for the most recent import of this data source. Two imports may
      # exist (the "without cleanup" and "with cleanup" contexts), so pick the latest importer_log.
      staging = HmisCsvTwentyTwentySix.importable_file_class('IncomeBenefits').
        where(IncomeBenefitsID: 'IB-1').
        order(importer_log_id: :desc).
        first

      # sanity check: this is the staging row whose total was filled by the cleanup
      expect(staging.TotalMonthlyIncome.to_i).to eq(100)

      # source_hash is derived from the source columns (including TotalMonthlyIncome). If the
      # cleanup had filled the total without refreshing source_hash, recomputing it here would
      # change the value, and the importer would mis-detect changes on subsequent imports.
      expect { staging.set_source_hash }.not_to change(staging, :source_hash)
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'IncomeBenefit': ['HmisCsvImporter::HmisCsvCleanup::FixMissingTotalMonthlyIncome'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwenty::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Fix missing total monthly income') || create(:fix_missing_total_monthly_income)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/missing_total_income',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end
