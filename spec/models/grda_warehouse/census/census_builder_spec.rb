# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Census::CensusBuilder, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { '2024-06-01'.to_date }
  let(:end_date) { '2024-07-30'.to_date }

  before do
    @project = create_project(project_type: 0)
    @client = create_client_with_warehouse_link
    @enrollment = create_enrollment(
      client: @client,
      project: @project,
      entry_date: start_date,
    )
    (start_date..end_date).each do |date|
      create_bed_night_service(enrollment: @enrollment, date: date)
    end
    create(:hud_inventory,
           ProjectID: @project.project_id,
           data_source: @project.data_source,
           InventoryStartDate: start_date,
           InventoryEndDate: end_date,
           BedInventory: 5)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  subject { described_class.new }

  describe '#create_census' do
    it 'persists census records for all dates in the range' do
      expect do
        subject.create_census(start_date, end_date)
      end.to change { GrdaWarehouse::Census::ByProject.where(project_id: @project.id, date: start_date..end_date).count }.by((end_date - start_date + 1).to_i)
      dates = GrdaWarehouse::Census::ByProject.where(project_id: @project.id).pluck(:date)
      expect(dates).to include(start_date)
      expect(dates).to include(end_date)
      expect(dates).to include(start_date + 1)
    end

    it 'counts beds on the InventoryStartDate boundary' do
      subject.create_census(start_date, end_date)
      record = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date)
      expect(record).not_to be_nil
      expect(record.beds).to eq(5)
    end
  end
end
