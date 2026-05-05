# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::Households do
  # Minimal host that satisfies the concern's runtime interface.
  # @households is set directly to bypass calculate_households (which needs a full generator).
  subject(:host) do
    Class.new { include HudReports::Households }.new.tap do |h|
      h.instance_variable_set(:@households, households_data)
      h.instance_variable_set(:@report, report)
    end
  end

  let(:report) { double('report', end_date: Date.parse('2024-01-31')) }
  let(:households_data) { {} }

  let(:entry_date) { Date.parse('2023-01-01') }

  let(:hoh) do
    {
      client_id: 1,
      relationship_to_hoh: 1,
      entry_date: entry_date,
      exit_date: nil,
      move_in_date: nil,
      age: 35,
      chronic_status: true,
      chronic_detail: :yes,
      pit_chronic_status: true,
      pit_chronic_detail: :yes,
    }
  end

  let(:adult) do
    {
      client_id: 2,
      relationship_to_hoh: 3,
      entry_date: entry_date,
      exit_date: nil,
      age: 28,
      chronic_status: false,
      chronic_detail: :no,
      pit_chronic_status: false,
      pit_chronic_detail: :no,
    }
  end

  let(:child) do
    {
      client_id: 3,
      relationship_to_hoh: 2,
      entry_date: entry_date,
      exit_date: nil,
      age: 10,
      chronic_status: false,
      chronic_detail: :no,
      pit_chronic_status: false,
      pit_chronic_detail: :no,
    }
  end

  describe '#calculate_household_chronic_status' do
    let(:hh_id) { 'hh-001' }

    context 'when household is not found' do
      it 'returns false' do
        expect(host.send(:calculate_household_chronic_status, 'missing-hh', 1)).to be false
      end
    end

    context 'with a household containing a chronic HoH and a child' do
      let(:households_data) { { hh_id => [hoh, child] } }

      it 'child inherits status from chronic HoH (project start rule)' do
        result = host.send(:calculate_household_chronic_status, hh_id, child[:client_id])
        expect(result[:status]).to be true
        expect(result[:detail]).to eq(:yes)
      end

      context 'when HoH is not chronic' do
        before do
          hoh[:chronic_status] = false
          hoh[:chronic_detail] = :no
          hoh[:pit_chronic_status] = false
          hoh[:pit_chronic_detail] = :no
        end

        it 'child does not inherit chronic status' do
          result = host.send(:calculate_household_chronic_status, hh_id, child[:client_id])
          expect(result[:status]).to be false
        end
      end

      context 'when child entered after HoH (not present at project start)' do
        before { child[:entry_date] = Date.parse('2023-06-01') }

        it 'HoH chronic and present at start satisfies project-start rule' do
          result = host.send(:calculate_household_chronic_status, hh_id, child[:client_id])
          expect(result[:status]).to be true
        end
      end
    end

    context 'with a household containing a chronic HoH and a non-chronic adult' do
      let(:households_data) { { hh_id => [hoh, adult] } }

      it 'adult gets status: true because HoH is chronic and present at same start (project start rule)' do
        result = host.send(:calculate_household_chronic_status, hh_id, adult[:client_id])
        expect(result[:status]).to be true
      end

      context 'when no household member is chronic' do
        before { hoh[:chronic_status] = false }

        it 'adult gets status: false' do
          result = host.send(:calculate_household_chronic_status, hh_id, adult[:client_id])
          expect(result[:status]).to be false
        end
      end
    end
  end

  describe '#household_chronic_status' do
    let(:hh_id) { 'hh-001' }
    let(:households_data) { { hh_id => [hoh, child] } }

    it 'returns chronic_status and chronic_detail keys for legacy callers' do
      result = host.send(:household_chronic_status, hh_id, child[:client_id])
      expect(result[:chronic_status]).to be true
      expect(result[:chronic_detail]).to eq(:yes)
    end
  end

  describe '#pit_household_chronic_status' do
    let(:hh_id) { 'hh-001' }
    let(:households_data) { { hh_id => [hoh] } }

    it 'returns pit_chronic_status key for legacy callers' do
      result = host.send(:pit_household_chronic_status, hh_id)
      expect(result[:pit_chronic_status]).to be true
    end

    it 'uses the HoH as the anchor when no client_id is given' do
      households_data[hh_id] = [hoh, child]
      result = host.send(:pit_household_chronic_status, hh_id)
      expect(result[:pit_chronic_status]).to be true
    end

    it 'adult gets pit_chronic_status based on own status (not inherited like project start)' do
      hoh[:pit_chronic_status] = false
      households_data[hh_id] = [hoh, adult]
      result = host.send(:pit_household_chronic_status, hh_id)
      expect(result[:pit_chronic_status]).to be false
    end
  end

  describe '#calculate_hh_move_in_date' do
    let(:hh_id) { 'hh-001' }

    let(:enrollment) do
      OpenStruct.new(
        entry_date: Date.parse('2023-01-01'),
        exit_date: nil,
        move_in_date: nil,
      )
    end

    context 'when household is not found' do
      it 'returns nil' do
        expect(host.send(:calculate_hh_move_in_date, 'missing-hh', enrollment)).to be_nil
      end
    end

    context 'when HoH has no move-in date' do
      let(:households_data) { { hh_id => [hoh] } }

      it 'returns nil' do
        expect(host.send(:calculate_hh_move_in_date, hh_id, enrollment)).to be_nil
      end
    end

    context 'when HoH has a valid move-in date' do
      let(:households_data) { { hh_id => [hoh] } }

      before { hoh[:move_in_date] = Date.parse('2023-03-01') }

      it 'inherits the HoH move-in date for a member present at housing' do
        result = host.send(:calculate_hh_move_in_date, hh_id, enrollment)
        expect(result).to eq(Date.parse('2023-03-01'))
      end

      it 'uses member entry_date for a late joiner (joined after housing)' do
        enrollment.entry_date = Date.parse('2023-04-01')
        result = host.send(:calculate_hh_move_in_date, hh_id, enrollment)
        expect(result).to eq(Date.parse('2023-04-01'))
      end

      it 'returns nil when member exited before HoH move-in' do
        enrollment.exit_date = Date.parse('2023-02-01') # Exited before HoH's 2023-03-01 move-in
        result = host.send(:calculate_hh_move_in_date, hh_id, enrollment)
        expect(result).to be_nil
      end

      it 'returns nil when the HoH move-in date is after the report end date' do
        hoh[:move_in_date] = Date.parse('2024-06-01') # After report end of 2024-01-31
        result = host.send(:calculate_hh_move_in_date, hh_id, enrollment)
        expect(result).to be_nil
      end
    end

    context 'when HoH move-in date precedes HoH entry date (data quality issue)' do
      let(:households_data) { { hh_id => [hoh] } }

      before do
        hoh[:entry_date] = Date.parse('2023-02-01')
        hoh[:move_in_date] = Date.parse('2023-01-01')
      end

      it 'disregards the invalid move-in date and returns nil' do
        result = host.send(:calculate_hh_move_in_date, hh_id, enrollment)
        expect(result).to be_nil
      end
    end
  end
end
