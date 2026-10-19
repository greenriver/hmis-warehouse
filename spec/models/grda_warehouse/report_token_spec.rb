###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ReportToken, type: :model do
  describe '#valid_for?' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:data_source) { create(:grda_warehouse_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source) }
    let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
    let!(:unrelated_project) { create(:hud_project, data_source: data_source, OrganizationID: create(:hud_organization, data_source: data_source).OrganizationID) }
    let!(:report) { create(:data_quality_report_version_five, project: project, requestor_id: user.id) }
    let!(:other_report) { create(:data_quality_report_version_five, project: project) }
    let!(:contact) { create(:grda_warehouse_contact_project, user: user, entity: project) }

    let(:contact_token) { described_class.create!(report_id: report.id, contact_id: contact.id) }
    let(:requestor_token) { described_class.create!(report_id: report.id, contact_id: user.id) }

    it 'accepts a contact token for the contact user and its report' do
      expect(contact_token.valid_for?(report_id: report.id, user: user)).to be(true)
    end

    it 'accepts a report id given as a string' do
      expect(contact_token.valid_for?(report_id: report.id.to_s, user: user)).to be(true)
    end

    it 'rejects a contact token for a different user' do
      expect(contact_token.valid_for?(report_id: report.id, user: other_user)).to be(false)
    end

    it 'rejects a contact token once the contact is deleted' do
      contact_token
      contact.destroy

      expect(contact_token.valid_for?(report_id: report.id, user: user)).to be(false)
    end

    it 'rejects a token for a different report' do
      expect(contact_token.valid_for?(report_id: other_report.id, user: user)).to be(false)
    end

    it 'rejects an expired token' do
      contact_token.update_columns(expires_at: 1.day.ago)

      expect(contact_token.valid_for?(report_id: report.id, user: user)).to be(false)
    end

    it 'accepts a requestor token for the report requestor' do
      expect(requestor_token.valid_for?(report_id: report.id, user: user)).to be(true)
    end

    it 'rejects a requestor token for another user' do
      expect(requestor_token.valid_for?(report_id: report.id, user: other_user)).to be(false)
    end

    it 'rejects a token whose contact_id is the user id when the user is not the report requestor' do
      token = described_class.create!(report_id: other_report.id, contact_id: user.id)

      expect(token.valid_for?(report_id: other_report.id, user: user)).to be(false)
    end

    it 'rejects a token whose contact_id is a contact of another user, for a requestor of the report' do
      other_contact = create(:grda_warehouse_contact_project, user: other_user, entity: project)
      token = described_class.create!(report_id: report.id, contact_id: other_contact.id)

      expect(token.valid_for?(report_id: report.id, user: user)).to be(false)
    end

    it 'accepts an organization contact token for the contact user' do
      org_contact = create(:grda_warehouse_contact_organization, user: other_user, entity: organization)
      token = described_class.create!(report_id: report.id, contact_id: org_contact.id)

      expect(token.valid_for?(report_id: report.id, user: other_user)).to be(true)
    end

    context 'when a contact id equals the requestor user id' do
      let(:requestor_token) { described_class.create!(report_id: report.id, contact_id: user.id) }

      it 'rejects the contact user when the contact is not a recipient of the report' do
        create(:grda_warehouse_contact_project, id: user.id, user: other_user, entity: unrelated_project)

        expect(requestor_token.valid_for?(report_id: report.id, user: other_user)).to be(false)
      end

      it 'accepts the contact user when the contact is a recipient of the report' do
        create(:grda_warehouse_contact_project, id: user.id, user: other_user, entity: project)

        expect(requestor_token.valid_for?(report_id: report.id, user: other_user)).to be(true)
      end
    end
  end
end
