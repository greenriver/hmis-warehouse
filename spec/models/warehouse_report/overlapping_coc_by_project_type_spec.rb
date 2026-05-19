###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe WarehouseReport::OverlappingCocByProjectType, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { Date.parse('2022-01-01') }
  let(:end_date)   { Date.parse('2022-12-31') }
  let(:coc_code_1) { 'MA-500' }
  let(:coc_code_2) { 'MA-516' }

  let(:coc1_shape) { double('coc1', cocnum: coc_code_1, cocname: 'Boston CoC') }
  let(:coc2_shape) { double('coc2', cocnum: coc_code_2, cocname: 'Massachusetts Balance of State CoC') }

  # Stub Shape::Coc DB lookups. coc_shape_by_cocnum is memoized via Memery
  # (prepended module), so we stub the underlying AR query instead of the
  # instance method.
  def stub_coc_shapes(mapping)
    coc_relation = instance_double(ActiveRecord::Relation)
    allow(GrdaWarehouse::Shape::Coc).to receive(:where).and_return(coc_relation)
    allow(coc_relation).to receive(:index_by).and_return(mapping)
  end

  before do
    stub_coc_shapes(coc_code_1 => coc1_shape, coc_code_2 => coc2_shape)
  end

  subject(:report) do
    described_class.new(
      coc_code_1: coc_code_1,
      coc_code_2: coc_code_2,
      start_date: start_date,
      end_date: end_date,
    )
  end

  # Builds a stubbed service_histories scope whose .where/.preload return
  # a plain array so group_by works in both details_clients and
  # limited_details_clients.
  def stub_service_histories(report, *service_doubles)
    arr = service_doubles.dup
    arr.define_singleton_method(:where) { |**| arr }
    arr.define_singleton_method(:preload) { |*| arr }
    allow(report).to receive(:service_histories).and_return(arr)
  end

  # ── Constructor validations ────────────────────────────────────────────────

  describe 'constructor' do
    it 'raises when both CoC codes are the same' do
      same = double('same_coc', cocnum: 'MA-500', cocname: 'Boston CoC')
      stub_coc_shapes('MA-500' => same)

      expect do
        described_class.new(
          coc_code_1: 'MA-500',
          coc_code_2: 'MA-500',
          start_date: start_date,
          end_date: end_date,
        )
      end.to raise_error(described_class::Error, /two different/)
    end

    it 'raises when start_date is after end_date' do
      expect do
        described_class.new(
          coc_code_1: coc_code_1,
          coc_code_2: coc_code_2,
          start_date: end_date,
          end_date: start_date,
        )
      end.to raise_error(described_class::Error, /before/)
    end

    it 'raises when date range exceeds 3 years' do
      expect do
        described_class.new(
          coc_code_1: coc_code_1,
          coc_code_2: coc_code_2,
          start_date: end_date.prev_year(3) - 1.day,
          end_date: end_date,
        )
      end.to raise_error(described_class::Error, /3 years/)
    end

    it 'raises on an invalid project_type' do
      expect do
        described_class.new(
          coc_code_1: coc_code_1,
          coc_code_2: coc_code_2,
          start_date: start_date,
          end_date: end_date,
          project_type: '999',
        )
      end.to raise_error(described_class::Error, /Invalid project type/)
    end
  end

  # ── #details_clients ──────────────────────────────────────────────────────

  describe '#details_clients' do
    let!(:source_client)      { create_client_with_warehouse_link(dob: 30.years.ago.to_date) }
    let!(:destination_client) { source_client.destination_client }

    before do
      allow(report).to receive(:overlapping_client_ids).and_return([destination_client.id])
      shs = double('shs', client_id: destination_client.id)
      stub_service_histories(report, shs)
    end

    it 'returns hashes with exactly the expected keys' do
      expect(report.details_clients.first.keys).to match_array([:label, :gender, :age_group, :race, :client_id])
    end
  end

  # ── #limited_details_clients ──────────────────────────────────────────────

  describe '#limited_details_clients' do
    let(:user)                { create(:user) }
    let!(:source_client)      { create_client_with_warehouse_link(dob: 25.years.ago.to_date) }
    let!(:destination_client) { source_client.destination_client }

    before do
      allow(report).to receive(:overlapping_client_ids).and_return([destination_client.id])
      allow(report).to receive(:enrollment_details).and_return([])
      shs = double('shs', client_id: destination_client.id)
      stub_service_histories(report, shs)
    end

    it 'returns hashes with exactly the expected keys' do
      expect(report.limited_details_clients(user).first.keys).to match_array([:label, :gender, :age_group, :race, :enrollments, :client_id])
    end
  end

  # ── #overlapping_client_ids ───────────────────────────────────────────────

  describe '#overlapping_client_ids' do
    let!(:project1) { create_project(project_type: 1, coc_code: coc_code_1) }
    let!(:project2) { create_project(project_type: 1, coc_code: coc_code_2) }

    let!(:shared_source)    { create_client_with_warehouse_link(dob: 30.years.ago.to_date) }
    let!(:coc1_only_source) { create_client_with_warehouse_link(dob: 25.years.ago.to_date) }

    let(:shared_dest)    { shared_source.destination_client }
    let(:coc1_only_dest) { coc1_only_source.destination_client }

    before do
      # Shared client: enrolled and has services in both CoCs
      e1 = create_enrollment(client: shared_source, project: project1, entry_date: start_date)
      e2 = create_enrollment(client: shared_source, project: project2, entry_date: start_date)
      create_bed_night_service(enrollment: e1, date: start_date + 1.day)
      create_bed_night_service(enrollment: e2, date: start_date + 1.day)

      # CoC-1-only client: enrolled and has services only in CoC 1
      e3 = create_enrollment(client: coc1_only_source, project: project1, entry_date: start_date)
      create_bed_night_service(enrollment: e3, date: start_date + 1.day)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end

    it 'includes clients enrolled in both CoCs' do
      expect(report.overlapping_client_ids).to include(shared_dest.id)
    end

    it 'excludes clients enrolled in only one CoC' do
      expect(report.overlapping_client_ids).not_to include(coc1_only_dest.id)
    end
  end
end
