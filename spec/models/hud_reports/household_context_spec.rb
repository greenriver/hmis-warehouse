# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdContext, type: :model do
  let(:report_instance) { create(:hud_reports_report_instance) }
  let!(:data_source) { create :data_source_fixed_id }
  let!(:client) { create :hud_client, data_source_id: data_source.id }
  let!(:project) { create :hud_project, data_source: data_source, organization: organization }
  let!(:organization) { create :hud_organization, data_source: data_source }
  let!(:enrollment) { create :she_entry, client_id: client.id, project_type: 1, date: '2015-01-05'.to_date, first_date_in_program: '2015-01-05'.to_date, last_date_in_program: '2015-03-10'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: data_source.id }

  it 'can be created with valid attributes' do
    context = described_class.new(
      report_instance: report_instance,
      service_history_enrollment: enrollment,
      data_source_id: data_source.id,
      household_id: 'HH123',
      household_type: 'adults_only',
      is_hoh: true,
    )

    expect(context).to be_valid
    expect(context.save).to be true
  end

  describe '.prune!' do
    let!(:recent_report) { create(:hud_reports_report_instance, created_at: 1.day.ago) }
    let!(:old_report) { create(:hud_reports_report_instance, created_at: 3.weeks.ago) }
    let!(:deleted_report) { create(:hud_reports_report_instance, created_at: 1.day.ago).tap(&:destroy) }

    let!(:recent_context) { create(:hud_reports_household_context, report_instance: recent_report, service_history_enrollment: enrollment) }
    let!(:old_context) { create(:hud_reports_household_context, report_instance: old_report, service_history_enrollment: enrollment) }
    let!(:deleted_report_context) { create(:hud_reports_household_context, report_instance: deleted_report, service_history_enrollment: enrollment) }
    let!(:orphaned_context) do
      ctx = build(:hud_reports_household_context, report_instance_id: 0, service_history_enrollment: enrollment)
      ctx.save!(validate: false)
      ctx
    end

    it 'removes old, deleted, and orphaned contexts' do
      expect { described_class.prune! }.to change(described_class, :count).by(-3)

      expect(described_class.exists?(recent_context.id)).to be true
      expect(described_class.exists?(old_context.id)).to be false
      expect(described_class.exists?(deleted_report_context.id)).to be false
      expect(described_class.exists?(orphaned_context.id)).to be false
    end
  end
end
