require 'rails_helper'

# NOTE:
# Homeless is true for ES, SH, SO, TH
# Literally Homeless is only true for ES, SH, SO
# PH only negates homeless after the move-in-date

RSpec.describe GrdaWarehouse::ServiceHistoryEnrollment, type: :model do
  let(:client) { 0 }
  let(:start_date) { Date.current }
  let(:end_date) { Date.current + 1.days }

  describe 'by range' do
    let!(:start_in_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date, last_date_in_program: end_date }
    let!(:start_before_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date - 1.day, last_date_in_program: end_date }
    let!(:start_after_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: end_date + 1.day, last_date_in_program: end_date + 2.days }

    let!(:end_in_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date - 1.day, last_date_in_program: end_date }
    let!(:end_before_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date - 2.days, last_date_in_program: start_date - 1.day }
    let!(:end_after_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date, last_date_in_program: end_date + 1.day }

    describe 'entry_within_date_range' do
      let(:scope) { GrdaWarehouse::ServiceHistoryEnrollment.entry_within_date_range(start_date: start_date, end_date: end_date) }

      it 'includes entry started within range' do
        expect(scope).to include start_in_range
      end

      it 'excludes entry started before range' do
        expect(scope).not_to include start_before_range
      end

      it 'excludes entry started after range' do
        expect(scope).not_to include start_after_range
      end
    end

    describe 'exit_within_date_range' do
      let(:scope) { GrdaWarehouse::ServiceHistoryEnrollment.exit_within_date_range(start_date: start_date, end_date: end_date) }

      it 'includes exit ended within range' do
        expect(scope).to include(end_in_range)
      end

      it 'excludes exit ended before range' do
        expect(scope).not_to include end_before_range
      end

      it 'excludes exit ended after range' do
        expect(scope).not_to include end_after_range
      end
    end
  end

  describe 'currently homeless' do
    let!(:data_source) { create :data_source_fixed_id }

    let!(:no_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
    let!(:no_move_in_ph) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }

    let!(:future_move_in_th) { create :grda_warehouse_service_history, :service_history_entry, :with_th_enrollment, client_id: 2, data_source_id: 1, move_in_date: Date.current + 1.days, first_date_in_program: start_date, last_date_in_program: end_date }
    let!(:future_move_in_ph) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 2, data_source_id: 1, move_in_date: Date.current + 1.days, first_date_in_program: start_date, last_date_in_program: end_date }

    let!(:past_move_in_th) { create :grda_warehouse_service_history, :service_history_entry, :with_th_enrollment, client_id: 3, data_source_id: 1, first_date_in_program: start_date, move_in_date: Date.yesterday, last_date_in_program: end_date }
    let!(:past_move_in_ph) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 3, data_source_id: 1, first_date_in_program: start_date, move_in_date: Date.yesterday, last_date_in_program: end_date }

    let(:homeless_scope) { GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: Date.current) }
    let(:literally_homeless_scope) { GrdaWarehouse::ServiceHistoryEnrollment.currently_homeless(date: Date.current, chronic_types_only: true) }

    # Client ID 1 (only no move in date)
    it 'includes no move in' do
      aggregate_failures do
        expect(homeless_scope).to include no_move_in
        expect(homeless_scope).to_not include no_move_in_ph
        expect(literally_homeless_scope).to include no_move_in
        expect(literally_homeless_scope).not_to include no_move_in_ph
      end
    end

    # Client ID 2 (only future move in date)
    it 'includes future move in' do
      aggregate_failures do
        expect(homeless_scope).to include future_move_in_th
        expect(homeless_scope).to_not include future_move_in_ph
        expect(literally_homeless_scope).not_to include future_move_in_th
        expect(literally_homeless_scope).not_to include future_move_in_ph
      end
    end

    # Client ID 3 (only past move in date)
    it 'does not include past move in' do
      aggregate_failures do
        expect(homeless_scope).not_to include past_move_in_th
        expect(homeless_scope).not_to include past_move_in_ph
        expect(literally_homeless_scope).not_to include past_move_in_th
        expect(literally_homeless_scope).not_to include past_move_in_ph
      end
    end

    # Client IDs mixed  (only past move in date)
    it 'does not include past move in' do
      past_move_in_th.update(client_id: 4)
      aggregate_failures do
        expect(homeless_scope).to include past_move_in_th
        expect(homeless_scope).not_to include past_move_in_ph
        expect(literally_homeless_scope).not_to include past_move_in_th
        expect(literally_homeless_scope).not_to include past_move_in_ph
      end
    end

    # Client ID 3 (only past move in date) and include some es that gets excluded
    it 'negates es with PH' do
      no_move_in.update(client_id: 3)
      aggregate_failures do
        # Excluded by PH
        expect(homeless_scope).not_to include no_move_in
        expect(homeless_scope).not_to include past_move_in_th
        expect(homeless_scope).not_to include past_move_in_ph
        # Excluded by TH & PH
        expect(literally_homeless_scope).not_to include no_move_in
        expect(literally_homeless_scope).not_to include past_move_in_th
        expect(literally_homeless_scope).not_to include past_move_in_ph
      end
    end

    # Client ID 4 (only past move in date) and include some es that gets excluded sometimes
    it 'negates es with TH' do
      past_move_in_th.update(client_id: 4)
      no_move_in.update(client_id: 4)
      aggregate_failures do
        expect(homeless_scope).to include no_move_in
        expect(homeless_scope).to include past_move_in_th
        expect(literally_homeless_scope).not_to include no_move_in
        expect(literally_homeless_scope).not_to include past_move_in_th
      end
    end
  end
end
