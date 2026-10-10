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

  def enroll(client, relationship: 2, household_id: 'HH1', **attrs)
    create(
      :hmis_hud_enrollment,
      data_source: hmis_data_source,
      client: client,
      project: project,
      household_id: household_id,
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

  it 'resolves the age of a member whose birthday is tomorrow' do
    enroll(create_client(dob: current_date - 18.years + 1.day))
    expect(resolve).to include('youngest_member_age' => 17)
  end

  it 'ignores exited members' do
    enroll(create_client(dob: current_date - 5.years), exit_date: current_date - 1.day)
    expect(resolve).to eq('size' => 1, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'counts DOB-less members in size but not ages' do
    enroll(create_client(dob: nil))
    expect(resolve).to eq('size' => 2, 'youngest_member_age' => 40, 'oldest_member_age' => 40)
  end

  it 'counts members without a destination client in size but not ages' do
    member = create(:hmis_hud_client, data_source: hmis_data_source, dob: current_date - 5.years)
    expect(member.warehouse_client_source).to be_nil
    enroll(member)
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

  context 'with several clients' do
    let(:other) { create_client(dob: current_date - 30.years) }
    let(:other_id) { other.destination_client.id }

    before do
      enroll(create_client(dob: current_date - 5.years))
      enroll(other, relationship: 1, household_id: 'HH2')
    end

    it 'resolves each client in a batch from their own household' do
      clients = GrdaWarehouse::Hud::Client.where(id: [destination_id, other_id])
      expect(resolver.call(clients, registry::SIZE)).to eq(destination_id => 2, other_id => 1)
      expect(resolver.call(clients, registry::YOUNGEST_MEMBER_AGE)).to eq(destination_id => 5, other_id => 30)
    end

    it 'selects households once per batch, and again when the batch changes' do
      expect(Hmis::Ce::Match::Expression::HouseholdSelector).to receive(:new).twice.and_call_original
      expect(resolve).to eq('size' => 2, 'youngest_member_age' => 5, 'oldest_member_age' => 40)
      expect(resolver.call(GrdaWarehouse::Hud::Client.where(id: other_id), registry::SIZE)).to eq(other_id => 1)
    end

    it 'reuses the batch when the same clients arrive in a different order' do
      expect(Hmis::Ce::Match::Expression::HouseholdSelector).to receive(:new).once.and_call_original
      resolver.call([hoh.destination_client, other.destination_client], registry::SIZE)
      expect(resolver.call([other.destination_client, hoh.destination_client], registry::SIZE)).to eq(destination_id => 2, other_id => 1)
    end
  end

  it 'resolves nil for clients with no open household' do
    create(:hmis_hud_exit, enrollment: hoh.enrollments.first, client: hoh, data_source: hmis_data_source, exit_date: current_date - 1.day)
    expect(resolve).to eq('size' => nil, 'youngest_member_age' => nil, 'oldest_member_age' => nil)
  end
end
