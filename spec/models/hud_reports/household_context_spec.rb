# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdContext, type: :model do
  let(:report_instance) { create(:hud_reports_report_instance) }
  let!(:data_source) { create :data_source_fixed_id }
  let!(:client) { create :hud_client, data_source_id: data_source.id }
  let!(:project) { create :hud_project, data_source: data_source, organization: organization }
  let!(:organization) { create :hud_organization, data_source: data_source }
  let!(:enrollment) { create :she_entry, client_id: client.id, project_type: 1, date: '2015-01-05'.to_date, first_date_in_program: '2015-01-05'.to_date, last_date_in_program: '2015-03-10'.to_date, project_id: project.ProjectID, organization_id: organization.OrganizationID, data_source_id: 1 }

  it 'can be created with valid attributes' do
    context = described_class.new(
      report_instance: report_instance,
      service_history_enrollment: enrollment,
      household_id: 'HH123',
      household_type: 'adults_only',
      is_hoh: true,
    )

    expect(context).to be_valid
    expect(context.save).to be true
  end

  it 'enforces uniqueness of service_history_enrollment_id per report_instance_id' do
    described_class.create!(
      report_instance: report_instance,
      service_history_enrollment: enrollment,
      household_id: 'HH123',
    )

    duplicate = described_class.new(
      report_instance: report_instance,
      service_history_enrollment: enrollment,
      household_id: 'HH456',
    )

    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
