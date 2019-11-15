require 'rails_helper'

RSpec.describe Health::CpMembers::EnrollmentRosterFile, type: :model do
  it 'reads a roster' do
    contents = File.read('spec/fixtures/files/health/roster/CP_member_enrollment_roster.csv')
    file = Health::CpMembers::EnrollmentRosterFile.create(content: contents)
    file.parse
    expect(Health::CpMembers::EnrollmentRoster.count).to eq(5)
  end
end
