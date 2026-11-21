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

  let(:form_processor) do
    assessment = create(:hmis_custom_assessment, values: { 'ssn' => real_ssn }, hud_values: { 'SSN' => real_ssn })
    assessment.form_processor.tap { |fp| fp.update!(backup_values: { 'ssn' => real_ssn }) }
  end

  let(:enrollment) do
    create(:grda_warehouse_hud_enrollment, data_source: hud_client.data_source, client: hud_client, LastPermanentStreet: '1 Real St', LastPermanentZIP: '02139')
  end

  let(:place) { GrdaWarehouse::Place.create!(location: '1 Real St/Boston/MA/02139/us', zipcode: '02139', lat: 42.3, lon: -71.1, lat_lon: { 'lat' => 42.3 }) }

  let(:staff_user) { create(:user, email: 'staff@example.org') }

  let(:eto_form) do
    GrdaWarehouse::HmisForm.create!(
      data_source_id: hud_client.data_source_id,
      answers: { sections: [{ questions: [{ question: 'Phone', answer: '617-555-1234' }] }] },
      api_response: { 'FirstName' => real_first_name },
      staff: 'Real Staff',
      client_case_managers: 'Real Case Manager',
    )
  end

  let(:eto_client) do
    GrdaWarehouse::HmisClient.create!(
      client_id: hud_client.id,
      response: { 'FirstName' => real_first_name }.to_json,
      processed_fields: { 'email' => 'client@example.org', 'phone' => '617-555-1234' },
      case_manager_attributes: { 'Email' => 'cm@example.org' },
    )
  end

  # Partitioned table whose primary key is (id, importer_log_id)
  let(:importer_client) do
    HmisCsvTwentyTwentyTwo::Importer::Client.create!(
      data_source_id: hud_client.data_source_id,
      importer_log_id: 1,
      pre_processed_at: Time.current,
      source_id: 1,
      source_type: 'GrdaWarehouse::Hud::Client',
      PersonalID: 'P1',
      FirstName: real_first_name,
    )
  end

  def reload_records
    [
      hud_client,
      apr_client,
      contact,
      case_note,
      form_submission,
      form_processor,
      enrollment,
      place,
      spm_2026_enrollment,
      dqt_living_situation,
      staff_user,
      eto_form,
      eto_client,
      importer_client,
    ].each(&:reload)
  end

  let(:database_names) { described_class.new.expected_databases }

  def perform_task(**opts)
    travel_to(today) do
      described_class.new.perform(confirm_databases: database_names, **opts)
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

    it 'clears form processor answer JSON' do
      expect { perform_task }.to change { form_processor.values }.to(nil).
        and change { form_processor.hud_values }.to(nil).
        and change { form_processor.backup_values }.to(nil)
    end

    it 'clears enrollment addresses and geocoding cache entries' do
      expect { perform_task }.to change { enrollment.LastPermanentStreet }.to(nil).
        and change { enrollment.LastPermanentZIP }.to(nil).
        and change { place.location }.to("Street#{place.id}").
        and change { place.zipcode }.to(nil).
        and change { place.lat }.to(nil).
        and change { place.lat_lon }.to(nil)
    end

    it 'clears ETO form answers and API payloads, leaving client payloads parseable' do
      expect { perform_task }.to change { eto_form.answers }.to({}).
        and change { eto_form.api_response }.to({}).
        and change { eto_form.staff }.to(nil).
        and change { eto_form.client_case_managers }.to(nil).
        and change { JSON.parse(eto_client.response) }.to({}).
        and change { eto_client.processed_fields }.to(nil).
        and change { eto_client.case_manager_attributes }.to({})
    end

    it 'scrubs partitioned importer tables keyed on more than id' do
      expect { perform_task }.to change { importer_client.FirstName }.to(nil)
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

  context 'with a database confirmation' do
    before { PaperTrailHelper.with_paper_trail { hud_client.update!(FirstName: 'Changed') } }

    it 'refuses a wrong database list and leaves data and versions untouched' do
      expect { described_class.new.perform(confirm_databases: ['some_other_db']) }.to raise_error(ArgumentError, /confirm_databases/)

      expect(hud_client.reload.first_name).to eq('Changed')
      expect(hud_client.versions.count).to be > 0
    end

    it 'refuses a list missing one database' do
      expect(database_names.size).to be > 1

      expect { described_class.new.perform(confirm_databases: database_names.drop(1)) }.to raise_error(ArgumentError, /confirm_databases/)
      expect(hud_client.reload.first_name).to eq('Changed')
    end

    it 'refuses a list with an extra database' do
      expect { described_class.new.perform(confirm_databases: database_names + ['some_other_db']) }.to raise_error(ArgumentError, /confirm_databases/)
      expect(hud_client.versions.count).to be > 0
    end

    it 'refuses a list missing the database holding a model\'s version table' do
      model = GrdaWarehouse::Hud::Client
      allow(model).to receive(:version_class_name).and_return('Health::HealthVersion')
      allow(Pii::Scrubber::ScrubbableModels).to receive(:all).and_return([model])
      health_database = HealthDbBase.connection.current_database
      without_health = database_names - [health_database]

      expect { described_class.new.perform(confirm_databases: without_health) }.to raise_error(ArgumentError, /#{Regexp.escape(health_database)}/)
      expect(hud_client.versions.count).to be > 0
    end

    it 'requires the keyword' do
      expect { described_class.new.perform }.to raise_error(ArgumentError, /confirm_databases/)
    end

    it 'prunes versions before scrubbing, so a scrub failure leaves no history' do
      failing = instance_double(Pii::Scrubber::ScrubModelPii)
      allow(failing).to receive(:perform).and_raise(RuntimeError, 'scrub failed')
      allow(Pii::Scrubber::ScrubModelPii).to receive(:new).and_return(failing)

      expect { described_class.new.perform(confirm_databases: database_names) }.to raise_error(RuntimeError, 'scrub failed')
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
