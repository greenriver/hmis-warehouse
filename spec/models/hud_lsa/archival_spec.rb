###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::Archival do
  let(:generators) do
    [
      HudLsa::Generators::Fy2022::Lsa,
      HudLsa::Generators::Fy2023::Lsa,
      HudLsa::Generators::Fy2024::Lsa,
      HudLsa::Generators::Fy2026::Lsa,
    ]
  end

  before(:all) do
    _ = HudLsa::Generators::Fy2022::Lsa
    _ = HudLsa::Generators::Fy2023::Lsa
    _ = HudLsa::Generators::Fy2024::Lsa
    _ = HudLsa::Generators::Fy2026::Lsa
  end

  describe 'attachment declarations on HudReports::ReportInstance' do
    it 'declares lsa_summary_results_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:lsa_summary_results_csv)
    end
  end

  describe 'generator registration' do
    it 'registers all LSA generators in HudReportArchival.generator_registry' do
      generators.each do |gen|
        expect(HudReportArchival.generator_registry[gen.title]).to(
          eq(gen),
          "Expected #{gen.title} to be registered but registry has: #{HudReportArchival.generator_registry.keys.inspect}",
        )
      end
    end
  end

  describe 'archival_csv_config' do
    let(:report_instance) do
      HudReports::ReportInstance.new(id: 42, report_name: 'placeholder', question_names: [])
    end

    it 'every generator config has exactly the expected attachment keys' do
      expected_keys = [:universe_members_csv, :lsa_summary_results_csv, :report_cells_csv]
      generators.each do |gen|
        config = gen.archival_csv_config(report_instance)
        expect(config.keys).to(
          contain_exactly(*expected_keys),
          "#{gen.name} config keys mismatch",
        )
      end
    end

    it 'each FY config scopes lsa_summary_results_csv to that FY SummaryResult class' do
      {
        HudLsa::Generators::Fy2022::Lsa => HudLsa::Fy2022::SummaryResult,
        HudLsa::Generators::Fy2023::Lsa => HudLsa::Fy2023::SummaryResult,
        HudLsa::Generators::Fy2024::Lsa => HudLsa::Fy2024::SummaryResult,
        HudLsa::Generators::Fy2026::Lsa => HudLsa::Fy2026::SummaryResult,
      }.each do |gen, expected_model|
        scope_relation = gen.archival_csv_config(report_instance)[:lsa_summary_results_csv][:scope].call
        expect(scope_relation.klass).to(
          eq(expected_model),
          "#{gen.name}: expected scope to use #{expected_model} but got #{scope_relation.klass}",
        )
      end
    end

    it 'every config entry has scope, filename, and delete_order keys' do
      generators.each do |gen|
        config = gen.archival_csv_config(report_instance)
        config.each do |name, entry|
          expect(entry).to have_key(:scope), "#{gen.name}##{name} missing :scope"
          expect(entry).to have_key(:filename), "#{gen.name}##{name} missing :filename"
          expect(entry).to have_key(:delete_order), "#{gen.name}##{name} missing :delete_order"
          expect(entry[:scope]).to respond_to(:call), "#{gen.name}##{name} :scope must be callable"
          expect(entry[:filename]).to respond_to(:call), "#{gen.name}##{name} :filename must be callable"
        end
      end
    end

    it 'delete_order for universe_members_csv is always 1 (deleted first)' do
      generators.each do |gen|
        config = gen.archival_csv_config(report_instance)
        expect(config[:universe_members_csv][:delete_order]).to(
          eq(1),
          "#{gen.name}: universe_members_csv should have delete_order: 1",
        )
      end
    end

    it 'delete_order for report_cells_csv is always the highest (deleted last)' do
      generators.each do |gen|
        config = gen.archival_csv_config(report_instance)
        max_order = config.values.map { |e| e[:delete_order] }.max
        expect(config[:report_cells_csv][:delete_order]).to(
          eq(max_order),
          "#{gen.name}: report_cells_csv should have the highest delete_order",
        )
      end
    end
  end
end
