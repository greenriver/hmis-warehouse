###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubAllPiiTask do
  let(:today) { Date.new(2024, 11, 16) }

  let(:real_first_name) { 'RealFirstName' }
  let(:real_middle_name) { 'RealMiddleName' }
  let(:real_last_name) { 'RealLastName' }
  let(:real_ssn) { '123456789' }
  let(:real_age) { 28 }
  let(:real_dob) { Date.new(1996, 10, 20) }

  let(:hud_client) do
    create(
      :grda_warehouse_hud_client,
      FirstName: real_first_name,
      MiddleName: real_middle_name,
      LastName: real_last_name,
      SSN: real_ssn,
      DOB: real_dob,
    )
  end

  let(:apr_client) do
    HudApr::Fy2020::AprClient.create!(
      first_name: real_middle_name,
      last_name: real_last_name,
      ssn: real_ssn,
      dob: real_dob,
      age: real_age,
    )
  end

  let(:case_note) { create(:hmis_hud_custom_case_note, content: "Client disclosed #{real_first_name} #{real_last_name}") }

  let(:form_submission) { create(:hmis_external_form_submission, raw_data: { 'first_name' => real_first_name }) }

  let(:spm_2026_enrollment) do
    HudSpmReport::Fy2026::SpmEnrollment.new(first_name: real_first_name, last_name: real_last_name).tap { |r| r.save!(validate: false) }
  end

  let(:dqt_living_situation) do
    HmisDataQualityTool::CurrentLivingSituation.create!(
      first_name: real_first_name,
      last_name: real_last_name,
      current_living_situation_id: 1,
      enrollment_id: 1,
      client_id: 1,
      report_id: 1,
    )
  end

  let(:contact) do
    GrdaWarehouse::Contact::Organization.create!(
      entity: create(:grda_warehouse_hud_organization, data_source: hud_client.data_source),
      first_name: real_first_name,
      last_name: real_last_name,
      email: 'contact@example.org',
    )
  end

  let(:staff_user) { create(:user, email: 'staff@example.org') }

  def reload_records
    [
      hud_client,
      apr_client,
      contact,
      case_note,
      form_submission,
      spm_2026_enrollment,
      dqt_living_situation,
      staff_user,
    ].each(&:reload)
  end

  def perform_task(...)
    travel_to(today) do
      described_class.new.perform(...)
    end
    reload_records
  end

  let(:scrubbed_age) { 30 }
  let(:scrubbed_dob) { Date.new(1994, 11, 16) }
  let(:fake_first_name) { 'FakeFirstName' }
  let(:fake_last_name) { 'FakeLastName' }
  let(:fake_middle_name) { 'FakeMiddleName' }
  let(:fake_ssn) { '999000000' }

  # stub faker to get reproducable test values
  before(:each) do
    allow(Faker::Name).to receive(:first_name).and_return(fake_first_name)
    allow(Faker::Name).to receive(:last_name).and_return(fake_last_name)
    allow(Faker::Name).to receive(:middle_name).and_return(fake_middle_name)
    allow(Faker::IdNumber).to receive(:invalid).and_return(fake_ssn)
    allow(Faker::Date).to receive(:between) do |kwargs|
      kwargs[:from] # Always returns the lower bound
    end
  end

  context 'with defaults' do
    it 'scrubs all PII' do
      expect do
        perform_task
      end.
        # hud client
        to change { hud_client.first_name }.to(nil).
        and change { hud_client.last_name }.to(nil).
        and change { hud_client.ssn }.to(nil).
        and change { hud_client.dob }.to(scrubbed_dob).
        and change { hud_client.age(today) }.to(scrubbed_age).
        # apr
        and change { apr_client.first_name }.to(nil).
        and change { apr_client.last_name }.to(nil).
        and change { apr_client.ssn }.to(nil).
        and change { apr_client.dob }.to(scrubbed_dob).
        and change { apr_client.age }.to(scrubbed_age)
    end

    it 'replaces required fields with placeholders and clears optional PII in models without a legacy scrub entry' do
      expect do
        perform_task
      end.to change { case_note.content }.to("Note#{case_note.id}").
        and change { form_submission.raw_data }.to({}).
        and change { spm_2026_enrollment.first_name }.to(nil).
        and change { spm_2026_enrollment.last_name }.to(nil).
        and change { dqt_living_situation.first_name }.to(nil).
        and change { dqt_living_situation.last_name }.to(nil)
    end

    it 'leaves staff login accounts alone' do
      expect { perform_task }.not_to(change { staff_user.email })
    end

    it 'scrubs STI subclass rows through the base class' do
      expect { perform_task }.to change { contact.first_name }.to(nil).
        and change { contact.last_name }.to(nil).
        and change { contact.email }.to(nil)
    end

    it 'deletes version history for scrubbed records' do
      PaperTrailHelper.with_paper_trail { hud_client.update!(FirstName: 'Changed') }
      expect(hud_client.versions.count).to be > 0

      perform_task

      expect(hud_client.versions.count).to eq(0)
    end
  end

  context 'with fake strategy' do
    it 'replaces client PII with fake data' do
      expect do
        perform_task(custom_scrubber: :fake)
      end.to change { apr_client.first_name }.to(fake_first_name).
        and change { apr_client.last_name }.to(fake_last_name).
        and change { apr_client.ssn }.to(fake_ssn).
        and change { apr_client.dob }.to(scrubbed_dob).
        and change { apr_client.age }.to(scrubbed_age)
    end

    it 'uses placeholders for required fields that have no fake generator' do
      expect do
        perform_task(custom_scrubber: :fake)
      end.to change { case_note.content }.to("Note#{case_note.id}").
        and change { form_submission.raw_data }.to({})
    end
  end
end
