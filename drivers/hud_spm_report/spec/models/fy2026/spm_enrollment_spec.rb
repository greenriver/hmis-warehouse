###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Fy2026::SpmEnrollment, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe '.create_enrollment_set' do
    before do
      @project = create_project(project_type: 0)
      @household_members = []
      build_household(
        projects: [@project],
        entry_date: '2022-01-01'.to_date,
        exit_date: nil,
        members: 2,
        household_id: 'income-household',
        date_to_street_essh: '2022-01-01'.to_date,
        include_move_in: true,
        move_in_offset: 5,
      ) do |client, enrollment|
        @household_members << { client: client, enrollment: enrollment }
      end

      @head = @household_members.find { |member| member[:enrollment].relationship_to_hoh == 1 }
      @child = @household_members.find { |member| member[:enrollment].relationship_to_hoh != 1 }
      @child[:enrollment].update(DateToStreetESSH: nil)
      @child[:client].update!(dob: Date.parse('2012-04-05'))

      create(
        :hud_income_benefit,
        enrollment: @head[:enrollment],
        data_source: @head[:enrollment].data_source,
        data_collection_stage: 1,
        information_date: @head[:enrollment].entry_date,
        earned_amount: 200,
        other_income_amount: 100,
        total_monthly_income: 300,
      )
      add_income_snapshot(
        enrollment: @head[:enrollment],
        information_date: '2023-01-15'.to_date,
        data_collection_stage: 5,
        earned_amount: 400,
        other_income_amount: 150,
      )

      @report = setup_report([@project.id], ['Measure 1'])
      @spm_enrollments = @report.spm_enrollments.index_by(&:client_id)
    end

    it 'captures income deltas for stayers' do
      hoh_spm = @spm_enrollments.fetch(@head[:enrollment].destination_client.id)
      expect(hoh_spm.previous_earned_income).to eq(200)
      expect(hoh_spm.current_earned_income).to eq(400)
      expect(hoh_spm.previous_non_employment_income).to eq(100)
      expect(hoh_spm.current_non_employment_income).to eq(150)
      expect(hoh_spm.previous_total_income).to eq(300)
      expect(hoh_spm.current_total_income).to eq(550)
    end

    it 'propagates head of household homelessness data to household members' do
      child_spm = @spm_enrollments.fetch(@child[:enrollment].destination_client.id)
      expect(child_spm.start_of_homelessness).to eq(Date.parse('2022-01-01'))
      expect(child_spm.move_in_date).to eq(@head[:enrollment].move_in_date)
    end
  end
end
