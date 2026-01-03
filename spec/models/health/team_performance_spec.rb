###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::TeamPerformance, type: :model do
  describe '#teams_for_picker' do
    it 'returns teams ordered by name without requiring team_counts' do
      user = create(:user)
      team_b = create(:coordination_team, name: 'B Team', team_coordinator: user)
      team_a = create(:coordination_team, name: 'A Team', team_coordinator: user)

      report = described_class.new(range: (Date.current.beginning_of_month..Date.current.end_of_month), team_scope: Health::CoordinationTeam.all)

      expect(report.teams_for_picker.pluck(:id)).to eq([team_a.id, team_b.id])
    end
  end

  describe '#patient_ids_for_team / #patient_ids_for_all_teams' do
    it 'returns active patient ids for the team within the report range' do
      cc1 = create(:user)
      cc2 = create(:user)
      team = create(:coordination_team, team_coordinator: cc1, name: 'Team 1')
      create(:user_care_coordinator, coordination_team: team, user: cc1)
      create(:user_care_coordinator, coordination_team: team, user: cc2)

      in_range = create(:patient, care_coordinator: cc1)
      out_of_range = create(:patient, care_coordinator: cc2)
      wrong_team = create(:patient, care_coordinator: create(:user))

      in_range.patient_referral.update!(enrollment_start_date: Date.current - 30.days, disenrollment_date: nil, current: true)
      out_of_range.patient_referral.update!(enrollment_start_date: Date.current - 2.years, disenrollment_date: Date.current - 18.months, current: false)

      range = (Date.current.beginning_of_month..Date.current.end_of_month)
      report = described_class.new(range: range, team_scope: Health::CoordinationTeam.where(id: team.id))

      expect(report.patient_ids_for_team(team)).to contain_exactly(in_range.id)
      expect(report.patient_ids_for_all_teams).to contain_exactly(in_range.id)
      expect(report.patient_ids_for_all_teams).not_to include(out_of_range.id, wrong_team.id)
    end
  end
end
