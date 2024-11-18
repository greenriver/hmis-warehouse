require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubAllPiiTask do
  let(:today) { Date.new(2024, 11, 16) }

  let(:real_first_name) { 'RealFirstName' }
  let(:real_middle_name) { 'RealMiddleName' }
  let(:real_last_name) { 'RealLastName' }
  let(:real_ssn) { '123-45-6789' }
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

  def reload_records
    [
      hud_client,
      apr_client,
    ].each(&:reload)
  end

  def perform_task(...)
    Timecop.travel(today) do
      described_class.new.perform(...)
    end
    reload_records
  end

  let(:scrubbed_age) { 30 }
  let(:scrubbed_dob) { Date.new(1994, 11, 16) }
  let(:fake_first_name) { 'FakeFirstName' }
  let(:fake_last_name) { 'FakeLastName' }
  let(:fake_middle_name) { 'FakeMiddleName' }
  let(:fake_ssn) { '999-00-0000' }

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

  context 'with null strategy' do
    it 'nullifies all PII' do
      expect do
        perform_task
      end.
        # hud client
        to change { hud_client.first_name }.to(nil).
        and change { hud_client.last_name }.to(nil).
        and change { hud_client.ssn }.to(nil).
        and change { hud_client.dob }.to(scrubbed_dob).
        and change { hud_client.age }.to(scrubbed_age).
        # apr
        and change { apr_client.first_name }.to(nil).
        and change { apr_client.last_name }.to(nil).
        and change { apr_client.ssn }.to(nil).
        and change { apr_client.dob }.to(scrubbed_dob).
        and change { apr_client.age }.to(scrubbed_age)
    end
  end

  context 'with fake strategy' do
    it 'replaces client PII with fake data' do
      expect do
        perform_task(variant: :fake)
      end.to change { apr_client.first_name }.to(fake_first_name).
        and change { apr_client.last_name }.to(fake_last_name).
        and change { apr_client.ssn }.to(fake_ssn).
        and change { apr_client.dob }.to(scrubbed_dob).
        and change { apr_client.age }.to(scrubbed_age)
    end
  end

  context 'with static strategy' do
    it 'replaces PII with static identifier-based values' do
      expect do
        perform_task(variant: :static)
      end.to change { apr_client.first_name }.to("FirstName#{apr_client.id}").
        and change { apr_client.last_name }.to("LastName#{apr_client.id}").
        and change { apr_client.ssn }.to(nil).
        and change { apr_client.dob }.to(scrubbed_dob).
        and change { apr_client.age }.to(scrubbed_age)
    end
  end
end
