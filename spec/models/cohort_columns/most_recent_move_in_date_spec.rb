# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::MostRecentMoveInDate, type: :model do
  let(:user) { create :user }
  let(:client) { create :hud_client }
  let(:cohort) { create :cohort }
  let(:cohort_client) { create :cohort_client, cohort: cohort, client: client }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }
  let(:data_source) { create :source_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }

  before(:all) do
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
  end

  # Helper method to create a complete service history enrollment
  def create_ph_enrollment(project_type:, entry_date:, move_in_date: nil, exit_date: nil)
    project = create(:hud_project, data_source: data_source, organization: organization, ProjectType: project_type)
    enrollment = create(:hud_enrollment, data_source: data_source, ProjectID: project.ProjectID, PersonalID: client.PersonalID, EntryDate: entry_date)
    create(:grda_warehouse_service_history,
           client: client,
           data_source: data_source,
           project: project,
           enrollment_group_id: enrollment.EnrollmentID,
           first_date_in_program: entry_date.to_date,
           last_date_in_program: exit_date&.to_date,
           move_in_date: move_in_date&.to_date,
           project_type: project_type,
           age: 35)
  end

  def update_cache
    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])
  end

  describe '#value' do
    context 'when client has no PH enrollments' do
      before do
        allow(client).to receive(:processed_service_history).and_return(nil)
      end

      it 'returns nil' do
        expect(column.value(cohort_client)).to be_nil
      end
    end

    context 'when client has PH enrollment with move-in date' do
      before do
        create_ph_enrollment(project_type: 13, entry_date: 6.months.ago, move_in_date: 3.months.ago)
        update_cache
      end

      it 'returns the move-in date' do
        expect(column.value(cohort_client)).to eq(3.months.ago.to_date.to_s)
      end
    end

    context 'when client has PH enrollment without move-in date' do
      before do
        create_ph_enrollment(project_type: 3, entry_date: 6.months.ago)
        update_cache
      end

      it 'returns nil' do
        expect(column.value(cohort_client)).to be_nil
      end
    end

    context 'when client has multiple PH enrollments with move-in dates' do
      before do
        create_ph_enrollment(project_type: 13, entry_date: 6.months.ago, move_in_date: 5.months.ago)
        create_ph_enrollment(project_type: 3, entry_date: 4.months.ago, move_in_date: 2.months.ago)
        update_cache
      end

      it 'returns the most recent move-in date' do
        expect(column.value(cohort_client)).to eq(2.months.ago.to_date.to_s)
      end
    end

    context 'when client has exited PH enrollment with move-in date' do
      before do
        create_ph_enrollment(project_type: 13, entry_date: 6.months.ago, move_in_date: 3.months.ago, exit_date: 1.month.ago)
        update_cache
      end

      it 'returns nil because enrollment is not ongoing' do
        expect(column.value(cohort_client)).to be_nil
      end
    end
  end

  describe 'column properties' do
    it 'is not editable' do
      expect(column.column_editable?).to be false
    end

    it 'has correct title' do
      expect(column.title).to eq('Most Recent Move-In Date')
    end

    it 'has correct column name' do
      expect(column.column).to eq('most_recent_move_in_date')
    end

    it 'is a date renderer' do
      expect(column.renderer).to eq('date')
    end
  end
end
