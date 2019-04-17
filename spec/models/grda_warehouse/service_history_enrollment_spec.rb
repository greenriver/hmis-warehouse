require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryEnrollment, type: :model do

  let(:client) { 0 }
  let(:start_date) { Date.today }
  let(:end_date) { Date.tomorrow }


  let!(:start_in_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:start_before_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: start_date - 1.day, last_date_in_program: end_date }
  let!(:start_after_range) { create :grda_warehouse_service_history, :service_history_entry, first_date_in_program: end_date + 1.day, last_date_in_program: end_date + 2.days }

  let!(:end_in_range) { create :grda_warehouse_service_history, :service_history_exit, first_date_in_program: start_date - 1.day, last_date_in_program: end_date }
  let!(:end_before_range) { create :grda_warehouse_service_history, :service_history_exit, first_date_in_program: start_date - 2.days, last_date_in_program: start_date - 1.day}
  let!(:end_after_range) { create :grda_warehouse_service_history, :service_history_exit, first_date_in_program: start_date, last_date_in_program: end_date + 1.day }

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
