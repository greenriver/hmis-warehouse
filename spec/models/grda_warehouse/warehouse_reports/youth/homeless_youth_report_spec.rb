require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport, type: :model do

  let!(:existing_intake) { create :intake, :existing_intake }
  let!(:new_intake) { create :intake, :new_intake }
  let!(:closed_intake) { create :intake, engagement_date: Date.parse('2018-12-01'), exit_date: Date.parse('2018-12-31')}

  let(:report) { build :homeless_youth_report }

  describe 'when a report is generated' do
    it 'includes only clients with services in the period' do
      expect(report.total_served).to include new_intake.client_id
      expect(report.total_served.count).to eq 1
    end

    # it 'counts homeless contacts' do
    #   expect(report.one_a).to eq
    # end
  end
end