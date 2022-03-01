require 'rails_helper'

model = GrdaWarehouse::Hud::Enrollment
RSpec.describe model, type: :model do
  describe 'When calculating chronic at project start' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      file_path = 'spec/fixtures/files/chronic'
      import_hmis_csv_fixture(file_path, version: 'AutoMigrate', run_jobs: true)
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'the database will have the correct number of source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(4)
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(5)
    end

    it 'there are the correct number of service history services' do
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: 'ESNbN').joins(:service_history_services).count).to eq(18)
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: 'SO').joins(:service_history_services).
        merge(GrdaWarehouse::ServiceHistoryService.service_excluding_extrapolated).count).to eq(3)
    end

    describe 'not chronically homeless' do
      it 'because of disability' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.DisablingCondition = 0
        expect(en.chronically_homeless_at_start?).to be(false)
      end

      it 'because of insufficient duration' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.DateToStreetESSH = en.EntryDate - 2.months
        en.TimesHomelessPastThreeYears = 99
        en.MonthsHomelessPastThreeYears = 99
        expect(en.chronically_homeless_at_start?).to be(false)
      end

      it 'TH because of prior living situation' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'TH')
        en.LivingSituation = 11
        en.LOSUnderThreshold = 0
        en.DateToStreetESSH = en.EntryDate - 13.months
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 15
        expect(en.chronically_homeless_at_start?).to be(false)
      end

      it 'PH because of prior living situation' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'PH')
        en.LivingSituation = 11
        en.LOSUnderThreshold = 0
        en.DateToStreetESSH = en.EntryDate - 13.months
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 15
        expect(en.chronically_homeless_at_start?).to be(false)
      end

      it 'Chronic isn\'t affected by time in project' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'PH')
        en.LivingSituation = 11
        en.DateToStreetESSH = en.EntryDate - 11.months
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 15
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(false)
      end

      it 'and prior living situation was homeless, because of insufficient duration' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'PH')
        en.LivingSituation = 16
        en.DateToStreetESSH = en.EntryDate - 2.months
        en.TimesHomelessPastThreeYears = 99
        en.MonthsHomelessPastThreeYears = 99
        expect(en.chronically_homeless_at_start?).to be(false)
      end
    end

    describe 'chronically homeless at start' do
      it 'ES NbN because of days prior' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.DateToStreetESSH = en.EntryDate - 365.days
        expect(en.chronically_homeless_at_start?).to be(false)
        en.DateToStreetESSH = en.EntryDate - 366.days
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'ES NbN self report' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 112
        expect(en.chronically_homeless_at_start?).to be(true)
        en.DisablingCondition = 0
        expect(en.chronically_homeless_at_start?).to be(false)
      end

      it 'ES because of days prior' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ES')
        en.DateToStreetESSH = en.EntryDate - 365.days
        expect(en.chronically_homeless_at_start?).to be(false)
        en.DateToStreetESSH = en.EntryDate - 366.days
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'ES self report' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ES')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 112
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'SO because of days prior' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'SO')
        en.DateToStreetESSH = en.EntryDate - 365.days
        expect(en.chronically_homeless_at_start?).to be(false)
        en.DateToStreetESSH = en.EntryDate - 366.days
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'SO self report' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'SO')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 112
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'TH because of prior living situation and self-report' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'TH')
        en.LivingSituation = 16
        en.LOSUnderThreshold = 0
        en.DateToStreetESSH = en.EntryDate - 13.months
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 15
        expect(en.chronically_homeless_at_start?).to be(true)
      end

      it 'PH because of prior living situation and self-report' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'PH')
        en.LivingSituation = 16
        en.LOSUnderThreshold = 0
        en.DateToStreetESSH = en.EntryDate - 13.months
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 15
        expect(en.chronically_homeless_at_start?).to be(true)
      end
    end

    describe 'chronically homeless at PIT' do
      it 'ES NbN because of days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.DateToStreetESSH = en.EntryDate - 350.days
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end

      it 'ES NbN self report + days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ESNbN')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 109
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end

      it 'ES because of days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ES')
        en.DateToStreetESSH = en.EntryDate - 300.days
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end

      it 'ES self report + days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'ES')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 109
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end

      it 'SO because of days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'SO')
        en.DateToStreetESSH = en.EntryDate - 363.days
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end

      it 'SO self report + days in shelter' do
        en = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'SO')
        en.TimesHomelessPastThreeYears = 4
        en.MonthsHomelessPastThreeYears = 110
        expect(en.chronically_homeless_at_start?(date: en.EntryDate + 6.months)).to be(true)
      end
    end
  end
end
