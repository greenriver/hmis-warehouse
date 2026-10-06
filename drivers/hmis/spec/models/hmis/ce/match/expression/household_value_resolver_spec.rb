# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::HouseholdValueResolver, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:configuration) { Hmis::Ce::Configuration.new }
  let(:resolver) { described_class.new(current_date: current_date, configuration: configuration) }
  let(:project) { create(:hmis_hud_project, data_source: hmis_data_source) }
  let(:registry) { Hmis::Ce::Match::Expression::HouseholdFieldRegistry }

  let(:hoh) { create_client(dob: current_date - 40.years) }
  let(:destination_id) { hoh.destination_client.id }

  def create_client(dob:)
    create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source, dob: dob)
  end

  def enroll(client, relationship: 2, **attrs)
    create(
      :hmis_hud_enrollment,
      data_source: hmis_data_source,
      client: client,
      project: project,
      household_id: 'HH1',
      relationship_to_ho_h: relationship,
      entry_date: current_date - 1.month,
      **attrs,
    )
  end

  def resolve
    clients = GrdaWarehouse::Hud::Client.where(id: destination_id)
    registry::ALL.to_h { |field| [field.key, resolver.call(clients, field)[destination_id]] }
  end

  before { enroll(hoh, relationship: 1) }

  it 'resolves a single-member household' do
    expect(resolve).to eq('size' => 1, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'resolves an adult + child household' do
    enroll(create_client(dob: current_date - 5.years))
    expect(resolve).to eq('size' => 2, 'youngest_member_age' => 5, 'oldest_member_age' => 40)
  end

  it 'resolves an adult-only household' do
    enroll(create_client(dob: current_date - 19.years))
    expect(resolve).to eq('size' => 2, 'youngest_member_age' => 19, 'oldest_member_age' => 40)
  end

  it 'ignores exited members' do
    enroll(create_client(dob: current_date - 5.years), exit_date: current_date - 1.day)
    expect(resolve).to eq('size' => 1, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'counts DOB-less members in size but not ages' do
    enroll(create_client(dob: nil))
    expect(resolve).to eq('size' => 2, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'resolves nil ages when no member has a DOB' do
    hoh.destination_client.update!(dob: nil)
    enroll(create_client(dob: nil))
    expect(resolve).to eq('size' => 2, 'youngest_member_age' => nil, 'oldest_member_age' => nil)
  end

  it 'uses the destination client DOB' do
    hoh.destination_client.update!(dob: current_date - 30.years)
    expect(resolve).to include('oldest_member_age' => 30)
  end

  it 'selects households once when resolving several fields for the same clients' do
    expect(Hmis::Ce::Match::Expression::HouseholdSelector).to receive(:new).once.and_call_original
    expect(resolve).to eq('size' => 1, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'resolves nil when the selected household has no open members left' do
    allow_any_instance_of(Hmis::Ce::Match::Expression::HouseholdSelector).to receive(:call).
      and_return({ destination_id => [hmis_data_source.id, 'GONE'] })
    expect(resolve).to eq('size' => nil, 'youngest_member_age' => nil, 'oldest_member_age' => nil)
  end

  it 'resolves nil for clients with no open household' do
    create(:hmis_hud_exit, enrollment: hoh.enrollments.first, client: hoh, data_source: hmis_data_source, exit_date: current_date - 1.day)
    expect(resolve).to eq('size' => nil, 'youngest_member_age' => nil, 'oldest_member_age' => nil)
  end
end
