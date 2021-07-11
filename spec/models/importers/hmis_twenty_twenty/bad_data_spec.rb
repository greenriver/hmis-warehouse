require 'rails_helper'

RSpec.describe Importers::HmisTwentyTwenty::Base, type: :model do
  describe 'When importing enrollments with bad data on 1/1/2020' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      travel_to Time.zone.local(2020, 1, 1) do
        import_hmis_csv_fixture(
          'spec/fixtures/files/importers/hmis_twenty_twenty/bad_data',
          version: '2020',
          run_jobs: false,
        )
      end
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end
    it 'the database will have three source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(134)
    end

    it 'all clients would have last names' do
      expect(GrdaWarehouse::Hud::Client.source.where.not(LastName: nil).count).to eq(134)
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 2020 (not 1920) if the date is less than a year ahead
      expect(client.DOB).to eq('2020-06-17'.to_date)
    end

    it 'the project has appropriate start and end dates' do
      project = GrdaWarehouse::Hud::Project.first
      expect(project.OperatingStartDate).to eq('2015-12-31'.to_date)
      expect(project.OperatingEndDate).to eq('2025-12-31'.to_date)
    end
  end

  describe 'When importing enrollments with bad data on 1/1/2021' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      travel_to Time.zone.local(2021, 1, 1) do
        import_hmis_csv_fixture(
          'spec/fixtures/files/importers/hmis_twenty_twenty/bad_data',
          version: '2020',
          run_jobs: false,
        )
      end
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 2020 (not 1920) if the date is in the past
      expect(client.DOB).to eq('2020-06-17'.to_date)
    end
  end

  describe 'When importing enrollments with bad data on 1/1/2021' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      travel_to Time.zone.local(2018, 1, 1) do
        import_hmis_csv_fixture(
          'spec/fixtures/files/importers/hmis_twenty_twenty/bad_data',
          version: '2020',
          run_jobs: false,
        )
      end
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 1920 (not 2020) if the date is more than a year in the future
      expect(client.DOB).to eq('1920-06-17'.to_date)
    end
  end
end
