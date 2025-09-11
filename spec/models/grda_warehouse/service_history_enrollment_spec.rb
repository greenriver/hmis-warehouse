###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  describe '.in_age_ranges' do
    let(:on_date) { Date.current }

    let!(:client_under_18) { create(:grda_warehouse_hud_client, DOB: on_date - 10.years) }
    let!(:client_18_to_24) { create(:grda_warehouse_hud_client, DOB: on_date - 20.years) }
    let!(:client_25_to_61) { create(:grda_warehouse_hud_client, DOB: on_date - 40.years) }
    let!(:client_over_61) { create(:grda_warehouse_hud_client, DOB: on_date - 70.years) }
    let!(:client_no_dob) { create(:grda_warehouse_hud_client, DOB: nil) }

    let!(:enrollment_under_18) { create(:grda_warehouse_service_history, client: client_under_18) }
    let!(:enrollment_18_to_24) { create(:grda_warehouse_service_history, client: client_18_to_24) }
    let!(:enrollment_25_to_61) { create(:grda_warehouse_service_history, client: client_25_to_61) }
    let!(:enrollment_over_61) { create(:grda_warehouse_service_history, client: client_over_61) }
    let!(:enrollment_no_dob) { create(:grda_warehouse_service_history, client: client_no_dob, age: nil) }

    subject(:scope_call) { described_class.in_age_ranges(age_ranges, on_date: on_date) }

    context 'when filtering for under_eighteen' do
      let(:age_ranges) { [:under_eighteen] }

      it 'returns only enrollments for clients under 18' do
        expect(scope_call).to contain_exactly(enrollment_under_18)
      end
    end

    context 'when filtering for eighteen_to_twenty_four' do
      let(:age_ranges) { [:eighteen_to_twenty_four] }

      it 'returns only enrollments for clients between 18 and 24' do
        expect(scope_call).to contain_exactly(enrollment_18_to_24)
      end
    end

    context 'when filtering for twenty_five_to_sixty_one' do
      let(:age_ranges) { [:twenty_five_to_sixty_one] }

      it 'returns only enrollments for clients between 25 and 61' do
        expect(scope_call).to contain_exactly(enrollment_25_to_61)
      end
    end

    context 'when filtering for over_sixty_one' do
      let(:age_ranges) { [:over_sixty_one] }

      it 'returns only enrollments for clients over 61' do
        expect(scope_call).to contain_exactly(enrollment_over_61)
      end
    end

    context 'with a client without a DOB' do
      let(:age_ranges) { GrdaWarehouse::ServiceHistoryEnrollment.available_age_ranges.keys }

      it 'does not include the enrollment for the client without a DOB' do
        expect(scope_call).not_to include(enrollment_no_dob)
      end
    end

    context 'when filtering for multiple age ranges' do
      let(:age_ranges) { [:under_eighteen, :over_sixty_one] }

      it 'returns enrollments for clients in all specified age ranges' do
        expect(scope_call).to contain_exactly(enrollment_under_18, enrollment_over_61)
      end
    end

    context 'when no age ranges are provided' do
      let(:age_ranges) { [] }

      it 'returns all enrollments' do
        expect(scope_call).to contain_exactly(
          enrollment_under_18,
          enrollment_18_to_24,
          enrollment_25_to_61,
          enrollment_over_61,
          enrollment_no_dob,
        )
      end
    end

    context 'when first_date_in_program is after on_date' do
      let(:on_date) { Date.current - 1.year }
      let!(:client) { create(:grda_warehouse_hud_client, DOB: Date.current - 18.years) }
      let!(:enrollment_eighteen_at_entry) do
        create(:grda_warehouse_service_history, client: client, first_date_in_program: Date.current)
      end
      context 'looking at 18 to 24' do
        let(:age_ranges) { [:eighteen_to_twenty_four] }
        it 'calculates age based on the later first_date_in_program and includes the enrollment' do
          # The client is 17 on on_date (under_eighteen), but turns 18 by first_date_in_program (eighteen_to_twenty_four).
          # This confirms the scope uses the later date for age calculation.
          expect(scope_call).to include(enrollment_eighteen_at_entry)
        end
      end

      context 'looking at under 18' do
        let(:age_ranges) { [:under_eighteen] }
        it 'calculates age based on the later first_date_in_program and does not include the enrollment' do
          # The client is 17 on on_date (under_eighteen), but turns 18 by first_date_in_program (eighteen_to_twenty_four).
          # This confirms the scope uses the later date for age calculation.
          expect(scope_call).to_not include(enrollment_eighteen_at_entry)
        end
      end
    end
  end
end
