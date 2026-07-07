###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::CpMembers::RosterFile, type: :model do
  it 'reads a roster' do
    contents = File.read('spec/fixtures/files/health/roster/CP_member_roster.csv')
    file = Health::CpMembers::RosterFile.create(content: contents)
    file.parse
    expect(Health::CpMembers::Roster.count).to eq(5)
  end
end
