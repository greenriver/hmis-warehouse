require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport, type: :model do

  let!(:existing_intake) { create :intake, :existing_intake }
  let!(:new_intake) { create :intake, :new_intake }
  let!(:closed_intake) { create :intake, engagement_date: Date.parse('2018-12-01'), exit_date: Date.parse('2018-12-31')}

  let!(:existing_homeless_street_outreach_contact) { create :intake, :existing_intake, :homeless, :street_outreach_contact}
  let!(:new_homeless_street_outreach_contact) { create :intake, :new_intake, :homeless, :street_outreach_contact}

  let!(:existing_at_risk_street_outreach_contact) { create :intake, :existing_intake, :at_risk, :street_outreach_contact}
  let!(:new_at_risk_street_outreach_contact) { create :intake, :new_intake, :at_risk, :street_outreach_contact}

  let!(:new_homeless_contact) { create :intake, :new_intake, :homeless, how_hear: 'Another'}
  let!(:new_at_risk_contact) { create :intake, :new_intake, :at_risk}

  let(:report) { build :homeless_youth_report }

  describe 'when a report is generated' do
    it 'counts clients with services in the period' do
      expect(report.total_served).to include new_intake.client_id
      expect(report.total_served.count).to eq 5
    end

    it 'counts homeless street outreach contacts' do
      expect(report.one_a.count).to eq 2
    end

    it 'counts at risk street outreach contacts' do
      expect(report.one_b.count).to eq 2
    end

    it 'counts new homeless contacts' do
      expect(report.two_a.count).to eq 1
      expect(report.two_a).to include new_homeless_contact.client_id
    end

    it 'counts new at risk contacts' do
      expect(report.two_b.count).to eq 1
      expect(report.two_b).to include new_at_risk_contact.client_id
    end

    it 'itemizes referral sources' do
      expect(report.two_c.keys.count).to eq 2
      expect(report.two_c.keys).to include 'Example'
      expect(report.two_c.keys).to include 'Another'
    end
  end
end