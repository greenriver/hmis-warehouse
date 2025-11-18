###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter, type: :model, exclude_fixpoints: true do
  include_context 'SPM test setup'

  describe '#enrollment_batches' do
    before do
      @eligible_project = create_project(project_type: 0)
      @other_project = create_project(project_type: 0, coc_code: 'ZZ-999')

      @eligible_enrollments = 3.times.map do |offset|
        create_enrollment(
          client: create_client_with_warehouse_link,
          project: @eligible_project,
          entry_date: '2023-01-01'.to_date + offset.days,
          exit_date: '2023-02-01'.to_date + offset.days,
        )
      end

      create_enrollment(
        client: create_client_with_warehouse_link,
        project: @other_project,
        entry_date: '2023-03-01'.to_date,
        exit_date: '2023-04-01'.to_date,
      )

      @report = setup_report([@eligible_project.id, @other_project.id], ['Measure 1'])
    end

    it 'yields HUD enrollments scoped to the configured CoC and project IDs' do
      filter = described_class.new(@report)
      batches = []
      filter.enrollment_batches(HudSpmReport::Fy2026::SpmEnrollment.enrollment_scope_for_members) do |batch|
        batches.concat(batch)
      end

      returned_ids = batches.map(&:id)
      expect(returned_ids).to match_array(@eligible_enrollments.map(&:id))
    end
  end
end
