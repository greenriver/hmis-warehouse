require 'rails_helper'

RSpec.describe GrdaWarehouse::ChEnrollment, type: :model do
  # need destination and source client, source enrollment and source disability
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:ds) { create :data_source_fixed_id }
  let!(:source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source: ds,
      PersonalID: client.PersonalID,
    )
  end
  let!(:warehouse_client) do
    create(
      :warehouse_client,
      destination: client,
      source: source_client,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:source_export) do
    create(
      :hud_export,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:source_project) do
    create(
      :hud_project,
      ProjectType: 1,
      TrackingMethod: 1,
      ExportID: source_export.ExportID,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a',
      ProjectID: source_project.ProjectID,
      EntryDate: Date.new(2021, 4, 1),
      DisablingCondition: 1,
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: Date.new(2020, 1, 1),
      LivingSituation: 16,
      LOSUnderThreshold: 1,
      ExportID: source_export.ExportID,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 113,
    )
  end

  context 'When enrollment is chronically homeless' do
    before(:each) do
      source_export.update(effective_export_end_date: Date.new(2021, 6, 1))
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    it 'Enrollment has processed_as' do
      expect(source_enrollment.reload.processed_as).not_to be_nil
    end

    context 'After processing' do
      before(:each) do
        GrdaWarehouse::ChEnrollment.maintain!
      end

      it 'ChEnrollment to exist' do
        expect(source_enrollment.ch_enrollment).to_not be_blank
      end

      it 'ChEnrollment to have same processed_as' do
        expect(source_enrollment.reload.processed_as).to eq(source_enrollment.ch_enrollment.processed_as)
      end

      it 'ChEnrollment to be chronically homeless' do
        expect(source_enrollment.ch_enrollment.chronically_homeless_at_entry).to eq(true)
      end
    end
  end

  context 'When enrollment is not chronically homeless' do
    before(:each) do
      source_enrollment.update(LivingSituation: 25, DateToStreetESSH: Date.new(2021, 3, 1), MonthsHomelessPastThreeYears: 103, processed_as: nil)
      source_export.update(effective_export_end_date: Date.new(2021, 6, 1))
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    context 'After processing' do
      before(:each) do
        GrdaWarehouse::ChEnrollment.maintain!
      end

      it 'ChEnrollment to have same processed_as' do
        expect(source_enrollment.reload.processed_as).to eq(source_enrollment.ch_enrollment.processed_as)
      end

      it 'ChEnrollment to not be chronically homeless' do
        expect(source_enrollment.ch_enrollment.chronically_homeless_at_entry).to eq(false)
      end
    end
  end
end
