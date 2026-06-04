###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../fy2026/shared_context'

RSpec.describe HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  let(:project) { create_project(project_type: 0) }

  def create_gendered_client(gender_attrs)
    client = create_client_with_warehouse_link
    GrdaWarehouse::WarehouseClient.find_by(source_id: client.id).destination.update!(gender_attrs)
    create_enrollment(client: client, project: project, entry_date: '2022-10-01'.to_date)
    client
  end

  def build_spm_report(filter_overrides = {})
    filter = default_filter.dup
    filter.update({ project_ids: [project.id] }.merge(filter_overrides))
    report = HudReports::ReportInstance.from_filter(filter, 'System Performance Measures - FY 2026', build_for_questions: ['Measure 1'])
    report.question_names = ['Measure 1']
    report.save!
    report
  end

  before do
    @woman = create_gendered_client(Woman: 1)
    @man = create_gendered_client(Man: 1)
    @nonbinary = create_gendered_client(NonBinary: 1)

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  def destination_id_for(source_client)
    GrdaWarehouse::WarehouseClient.find_by(source_id: source_client.id).destination.id
  end

  describe '#service_history_enrollment_scope' do
    context 'with a gender filter' do
      it 'does not raise' do
        report = build_spm_report(genders: [0])
        expect { described_class.new(report).service_history_enrollment_scope.load }.not_to raise_error
      end

      it 'returns only enrollments for the selected gender' do
        report = build_spm_report(genders: [0]) # Woman only
        client_ids = described_class.new(report).service_history_enrollment_scope.pluck(:client_id)

        expect(client_ids).to include(destination_id_for(@woman))
        expect(client_ids).not_to include(destination_id_for(@man))
        expect(client_ids).not_to include(destination_id_for(@nonbinary))
      end
    end

    context 'with a race filter' do
      before do
        GrdaWarehouse::WarehouseClient.find_by(source_id: @woman.id).destination.update!(AmIndAKNative: 1)
      end

      it 'does not raise' do
        report = build_spm_report(races: ['AmIndAKNative'])
        expect { described_class.new(report).service_history_enrollment_scope.load }.not_to raise_error
      end

      it 'returns only enrollments for the selected race' do
        report = build_spm_report(races: ['AmIndAKNative'])
        client_ids = described_class.new(report).service_history_enrollment_scope.pluck(:client_id)

        expect(client_ids).to include(destination_id_for(@woman))
        expect(client_ids).not_to include(destination_id_for(@man))
      end
    end
  end
end
