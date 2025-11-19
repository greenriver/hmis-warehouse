###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  include_context 'DQ Tool test setup'

  describe 'Inventory Metrics' do
    describe 'Dedicated Bed Issues' do
      context 'with matching bed counts' do
        before do
          @project = create_project(project_type: 1) # ES
          @project.reload
          expect(@project.project_cocs.exists?).to be true
          expect(@project.project_cocs.pluck(:CoCCode)).to include('MA-500')

          @inventory = create(
            :hud_inventory,
            ProjectID: @project.ProjectID,
            project: @project,
            data_source: data_source,
            CoCCode: 'MA-500',
            inventory_start_date: '2022-10-01'.to_date,
            inventory_end_date: '2023-09-30'.to_date,
            bed_inventory: 10,
            ch_vet_bed_inventory: 2,
            youth_vet_bed_inventory: 1,
            vet_bed_inventory: 1,
            ch_youth_bed_inventory: 1,
            youth_bed_inventory: 2,
            ch_bed_inventory: 2,
            other_bed_inventory: 1,
          )
          @inventory.reload
          # Sum: 2+1+1+1+2+2+1 = 10, matches bed_inventory
          @report = setup_report([@project.id])
        end

        it 'does not flag matching bed counts' do
          expect_result(title: 'Sum of Dedicated Beds does not Equal Total Beds')
        end
      end

      context 'with mismatched bed counts' do
        before do
          @project = create_project(project_type: 1) # ES
          @project.reload
          expect(@project.project_cocs.exists?).to be true
          expect(@project.project_cocs.pluck(:CoCCode)).to include('MA-500')

          @inventory = create(
            :hud_inventory,
            ProjectID: @project.ProjectID,
            project: @project,
            data_source: data_source,
            CoCCode: 'MA-500',
            inventory_start_date: '2022-10-01'.to_date,
            inventory_end_date: '2023-09-30'.to_date,
            bed_inventory: 100, # Sum: 2+1+1+1+2+2+0 = 9, doesn't match 100
            ch_vet_bed_inventory: 2,
            youth_vet_bed_inventory: 1,
            vet_bed_inventory: 1,
            ch_youth_bed_inventory: 1,
            youth_bed_inventory: 2,
            ch_bed_inventory: 2,
            other_bed_inventory: 0,
          )
          @inventory.reload
          @report = setup_report([@project.id])
        end

        it 'flags mismatched bed counts' do
          expect_result(title: 'Sum of Dedicated Beds does not Equal Total Beds', invalid_count: 1)
        end
      end

      context 'with zero total beds' do
        before do
          @project = create_project(project_type: 1) # ES
          @project.reload
          expect(@project.project_cocs.exists?).to be true
          expect(@project.project_cocs.pluck(:CoCCode)).to include('MA-500')

          @inventory = create(
            :hud_inventory,
            ProjectID: @project.ProjectID,
            project: @project,
            data_source: data_source,
            CoCCode: 'MA-500',
            inventory_start_date: '2022-10-01'.to_date,
            inventory_end_date: '2023-09-30'.to_date,
            bed_inventory: 0,
            ch_vet_bed_inventory: 0,
            youth_vet_bed_inventory: 0,
            vet_bed_inventory: 0,
            ch_youth_bed_inventory: 0,
            youth_bed_inventory: 0,
            ch_bed_inventory: 0,
            other_bed_inventory: 0,
          )
          @inventory.reload
          @report = setup_report([@project.id])
        end

        it 'does not flag zero beds' do
          expect_result(title: 'Sum of Dedicated Beds does not Equal Total Beds')
        end
      end
    end
  end
end
