require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  let(:client) { 0 }
  let(:start_date) { Date.today }
  let(:end_date) { Date.tomorrow }
  let!(:data_source) { create :data_source_fixed_id }

  let!(:no_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:no_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 1, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:no_move_in_services) { create_services_for no_move_in }
  let!(:no_move_in_enrollment_services) { create_services_for no_move_in_enrollment }

  let!(:future_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 2, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:future_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 2, data_source_id: 1, move_in_date: Date.tomorrow, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:future_move_in_services) { create_services_for future_move_in }
  let!(:future_move_in_enrollment_services) { create_services_for future_move_in_enrollment }

  let!(:past_move_in) { create :grda_warehouse_service_history, :service_history_entry, client_id: 3, data_source_id: 1, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:past_move_in_enrollment) { create :grda_warehouse_service_history, :service_history_entry, :with_ph_enrollment, client_id: 3, data_source_id: 1, move_in_date: Date.yesterday, first_date_in_program: start_date, last_date_in_program: end_date }
  let!(:past_move_in_services) { create_services_for past_move_in }
  let!(:past_move_in_enrollment_services) { create_services_for past_move_in_enrollment }

  it 'has services for all enrollment days' do
    expect(GrdaWarehouse::ServiceHistoryService.all).to include(*no_move_in_services)
    expect(GrdaWarehouse::ServiceHistoryService.all).to include(*future_move_in_services)
    expect(GrdaWarehouse::ServiceHistoryService.all).to include(*past_move_in_services)
  end

  describe 'homeless only' do
    let(:scope) { GrdaWarehouse::ServiceHistoryService.homeless_only(start_date: start_date, end_date: end_date) }

    it 'includes no move in' do
      expect(scope).to include(*no_move_in_services)
    end

    it 'includes future move in' do
      expect(scope).to include(*future_move_in_services)
    end

    it 'does not include past move in' do
      expect(scope).not_to include(*past_move_in_services)
    end
  end

  def create_services_for(enrollment)
    # Something in the way SHS is implemented (maybe the table partitioning) prevents create
    # from returning the id, so we create the record, and then look it up
    services = []
    (enrollment.first_date_in_program..enrollment.last_date_in_program).map do |date|
      GrdaWarehouse::ServiceHistoryService.create!(
        record_type: 'service',
        service_history_enrollment: enrollment,
        client_id: enrollment.client_id,
        project_type: enrollment.computed_project_type,
        date: date,
      )
      services << GrdaWarehouse::ServiceHistoryService.last
    end
    services
  end
end
