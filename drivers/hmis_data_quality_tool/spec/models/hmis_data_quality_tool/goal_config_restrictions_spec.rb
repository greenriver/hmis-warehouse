###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  include_context 'DQ Tool test setup'

  describe 'goal config restrictions on pivot_details' do
    let!(:project) { create_project(project_type: 1) } # ES

    before do
      client = create_client_with_warehouse_link
      create_enrollment(client: client, project: project)
      HmisDataQualityTool::Goal.where(coc_code: 'MA-500').destroy_all
    end

    after do
      HmisDataQualityTool::Goal.where(coc_code: 'MA-500').destroy_all
    end

    context 'when entry_date_entered_length is disabled' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', entry_date_entered_length: -1)
        @report = setup_report([project.id])
      end

      it 'excludes entry_date_entry_issues from pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).not_to include(:entry_date_entry_issues)
      end

      it 'excludes entry_date_entry_issues from results' do
        slugs = @report.results.map(&:slug)
        expect(slugs).not_to include('entry_date_entry_issues')
      end
    end

    context 'when entry_date_entered_length is enabled' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', entry_date_entered_length: 3)
        @report = setup_report([project.id])
      end

      it 'includes entry_date_entry_issues in pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).to include(:entry_date_entry_issues)
      end

      it 'includes entry_date_entry_issues in results' do
        slugs = @report.results.map(&:slug)
        expect(slugs).to include('entry_date_entry_issues')
      end
    end

    context 'when exit_date_entered_length is disabled' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', exit_date_entered_length: -1)
        @report = setup_report([project.id])
      end

      it 'excludes exit_date_entry_issues from pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).not_to include(:exit_date_entry_issues)
      end

      it 'excludes exit_date_entry_issues from results' do
        slugs = @report.results.map(&:slug)
        expect(slugs).not_to include('exit_date_entry_issues')
      end
    end

    context 'when exit_date_entered_length is enabled' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', exit_date_entered_length: 3)
        @report = setup_report([project.id])
      end

      it 'includes exit_date_entry_issues in pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).to include(:exit_date_entry_issues)
      end
    end

    context 'when expose_ch_calculations is false' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', expose_ch_calculations: false)
        @report = setup_report([project.id])
      end

      it 'excludes CH slugs from pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).not_to include(:date_to_street_issues)
        expect(slugs).not_to include(:times_homeless_issues)
        expect(slugs).not_to include(:months_homeless_issues)
      end

      it 'excludes CH slugs from results' do
        slugs = @report.results.map(&:slug)
        expect(slugs).not_to include('date_to_street_issues')
        expect(slugs).not_to include('times_homeless_issues')
        expect(slugs).not_to include('months_homeless_issues')
      end
    end

    context 'when show_annual_assessments is false' do
      before do
        HmisDataQualityTool::Goal.create!(coc_code: 'MA-500', show_annual_assessments: false)
        @report = setup_report([project.id])
      end

      it 'excludes annual_assessment_issues from pivot_details groups' do
        slugs = @report.pivot_details.groups.values.flat_map(&:keys)
        expect(slugs).not_to include(:annual_assessment_issues)
      end

      it 'excludes annual_assessment_issues from results' do
        slugs = @report.results.map(&:slug)
        expect(slugs).not_to include('annual_assessment_issues')
      end
    end
  end
end
