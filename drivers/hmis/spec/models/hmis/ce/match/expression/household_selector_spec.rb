# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::HouseholdSelector, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.current }
  let(:configuration) { Hmis::Ce::Configuration.new }
  let(:selector) { described_class.new(configuration: configuration) }
  let(:project) { create(:hmis_hud_project, data_source: hmis_data_source) }

  let(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source) }
  let(:destination_id) { client.destination_client.id }

  def create_client
    create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source)
  end

  def enroll(client, household_id:, project: self.project, relationship: 2, **attrs)
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

  def household(id)
    [hmis_data_source.id, id]
  end

  it 'omits clients with no open household' do
    enroll(client, household_id: 'HH1', relationship: 1, exit_date: current_date - 1.day)
    expect(selector.call([destination_id])).to eq({})
  end

  it 'treats an enrollment exiting today as exited' do
    enroll(client, household_id: 'HH1', relationship: 1, exit_date: current_date)
    expect(selector.call([destination_id])).to eq({})
  end

  it 'includes WIP enrollments' do
    create(:hmis_hud_wip_enrollment, data_source: hmis_data_source, client: client, project: project, household_id: 'HH1')
    expect(selector.call([destination_id])).to eq({ destination_id => household('HH1') })
  end

  it 'picks the household with the most open members' do
    # SMALL is created last so the later tiebreakers (DateUpdated, id) favor it; only size can pick BIG
    enroll(client, household_id: 'BIG', relationship: 1)
    enroll(client, household_id: 'SMALL', relationship: 1)
    enroll(create_client, household_id: 'BIG')
    enroll(create_client, household_id: 'SMALL', exit_date: current_date - 1.day) # exited members don't count

    expect(selector.call([destination_id])).to eq({ destination_id => household('BIG') })
  end

  it 'breaks size ties by most recent HoH entry date' do
    # OLDER is created last so the later tiebreakers (DateUpdated, id) favor it; only HoH entry date can pick NEWER
    enroll(create_client, household_id: 'NEWER', relationship: 1, entry_date: current_date - 1.week)
    enroll(client, household_id: 'NEWER', relationship: 2, entry_date: current_date - 2.months)
    enroll(client, household_id: 'OLDER', relationship: 1, entry_date: current_date - 2.months)
    # a non-HoH member entering after NEWER's HoH, so only the HoH's EntryDate counts
    enroll(create_client, household_id: 'OLDER', entry_date: current_date - 1.day)

    expect(selector.call([destination_id])).to eq({ destination_id => household('NEWER') })
  end

  it 'breaks remaining ties by the client enrollment DateUpdated' do
    enroll(client, household_id: 'FRESH', relationship: 1, date_updated: 1.day.ago)
    enroll(client, household_id: 'STALE', relationship: 1, date_updated: 2.days.ago)
    expect(selector.call([destination_id])).to eq({ destination_id => household('FRESH') })
  end

  it 'breaks remaining ties by the highest client enrollment id' do
    date_updated = 1.day.ago.change(usec: 0)
    enroll(client, household_id: 'FIRST', relationship: 1, date_updated: date_updated)
    enroll(client, household_id: 'SECOND', relationship: 1, date_updated: date_updated)
    expect(selector.call([destination_id])).to eq({ destination_id => household('SECOND') })
  end

  it 'selects a household for each requested client in a batch' do
    other_client = create_client
    unrequested_member = create_client
    enroll(client, household_id: 'SOLO', relationship: 1)
    enroll(other_client, household_id: 'SHARED', relationship: 1)
    enroll(unrequested_member, household_id: 'SHARED')

    other_id = other_client.destination_client.id
    expect(selector.call([destination_id, other_id])).to eq(
      { destination_id => household('SOLO'), other_id => household('SHARED') },
    )
  end

  it 'gives every requested member of a shared household that household' do
    other_client = create_client
    enroll(client, household_id: 'SHARED', relationship: 1)
    enroll(other_client, household_id: 'SHARED')

    other_id = other_client.destination_client.id
    expect(selector.call([destination_id, other_id])).to eq(
      { destination_id => household('SHARED'), other_id => household('SHARED') },
    )
  end

  context 'with an eligibility project group' do
    let(:other_project) { create(:hmis_hud_project, data_source: hmis_data_source) }
    let(:project_group) { create(:hmis_project_group, data_source: hmis_data_source, with_projects: [project]) }

    before do
      allow(configuration).to receive(:eligibility_project_group).and_return(project_group)
    end

    it 'only considers households from the client enrollments in the group' do
      enroll(client, household_id: 'IN_GROUP', relationship: 1)
      enroll(client, household_id: 'OUT_OF_GROUP', relationship: 1, project: other_project)
      enroll(create_client, household_id: 'OUT_OF_GROUP', project: other_project)

      expect(selector.call([destination_id])).to eq({ destination_id => household('IN_GROUP') })
    end
  end

  it 'ignores the lookback window' do
    allow(configuration).to receive(:eligibility_lookback_months).and_return(1)
    enroll(client, household_id: 'HH1', relationship: 1, exit_date: current_date - 1.week)
    expect(selector.call([destination_id])).to eq({})
  end
end
