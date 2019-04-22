require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport, type: :model do
  let!(:existing_intake) { create :intake, :existing_intake }
  let!(:new_intake) { create :intake, :new_intake }
  let!(:closed_intake) { create :intake, engagement_date: Date.parse('2018-12-01'), exit_date: Date.parse('2018-12-31') }

  let!(:existing_homeless_street_outreach_contact) { create :intake, :existing_intake, :homeless, :street_outreach_contact }
  let!(:new_homeless_street_outreach_contact) { create :intake, :new_intake, :homeless, :street_outreach_contact }

  let!(:existing_at_risk_street_outreach_contact) { create :intake, :existing_intake, :at_risk, :street_outreach_contact }
  let!(:new_at_risk_street_outreach_contact) { create :intake, :new_intake, :at_risk, :street_outreach_contact }

  let!(:new_homeless_contact) { create :intake, :new_intake, :homeless, how_hear: 'Another' }
  let!(:new_at_risk_contact) { create :intake, :new_intake, :at_risk }

  let!(:existing_case_management_existing_client) { create :case_management, :existing_case_management, client_id: existing_intake.client_id }
  let!(:new_case_management_existing_client) { create :case_management, :new_case_management, client_id: existing_intake.client_id }
  let!(:new_case_management_new_client) { create :case_management, :new_case_management, client_id: new_intake.client_id }

  let!(:turned_away_at_risk) { create :intake, :new_intake, :at_risk, turned_away: true }

  let!(:existing_financial_assistance) { create :financial_assistance, :existing_financial_assistance, client_id: existing_intake.client_id }
  let!(:new_financial_assistance) { create :financial_assistance, :new_financial_assistance, client_id: existing_intake.client_id }

  let!(:existing_referral_out) { create :referral_out, :existing_referral_out, client_id: existing_intake.client_id }
  let!(:new_referral_out) { create :referral_out, :new_referral_out, client_id: existing_intake.client_id }

  let(:report) { build :homeless_youth_report }

  describe 'when a report is generated' do
    it 'counts clients with services in the period' do
      expect(report.total_served).to include new_intake.client_id
      expect(report.total_served.count).to eq 6
    end

    # A1

    it 'counts homeless street outreach contacts' do
      expect(report.one_a.count).to eq 2
    end

    it 'counts at risk street outreach contacts' do
      expect(report.one_b.count).to eq 2
    end

    # A2

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

    # A3

    it 'counts youth at risk of homelessness at start' do
      expect(report.three_a.count).to eq 2
      expect(report.three_a).to include new_at_risk_street_outreach_contact.client_id
      expect(report.three_a).to include new_at_risk_contact.client_id
    end

    it 'counts continuing clients with case management' do
      expect(report.three_b.count).to eq 1
      expect(report.three_b).to include new_case_management_existing_client.client_id
    end

    it 'counts at risk turned away' do
      expect(report.three_c.count).to eq 1
      expect(report.three_c).to include turned_away_at_risk.client_id
    end

    # A4

    it 'counts homeless new intakes' do
      expect(report.four_a.count).to eq 2
    end

    it 'counts at risk new intakes' do
      pending 'not clear what this should be'
      expect(report.four_b.count).to eq 2
    end

    it 'counts continuing clients with case management' do
      expect(report.four_c.count).to eq 1
    end

    # A5

    it 'counts clients with financial assistance in interval' do
      expect(report.five_a.count).to eq 1
    end

    it 'counts clients without financial assistance in interval' do
      expect(report.five_b.count).to eq 7
    end

    # A6

    it 'count clients with referrals out in the interval' do
      expect(report.six_a.count).to eq 1
    end
  end
end
