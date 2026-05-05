###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::Archival do
  let(:generators) do
    [
      HudSpmReport::Generators::Fy2020::Generator,
      HudSpmReport::Generators::Fy2023::Generator,
      HudSpmReport::Generators::Fy2024::Generator,
      HudSpmReport::Generators::Fy2026::Generator,
    ]
  end

  # Ensure all generators (and their included concerns) are loaded before any example runs.
  before(:all) do
    # Force autoloading so each generator's include HudSpmReport::Archival runs
    # and registers it in HudReportArchival.generator_registry before examples run.
    _ = HudSpmReport::Generators::Fy2020::Generator
    _ = HudSpmReport::Generators::Fy2023::Generator
    _ = HudSpmReport::Generators::Fy2024::Generator
    _ = HudSpmReport::Generators::Fy2026::Generator
  end

  describe 'attachment declarations on HudReports::ReportInstance' do
    it 'declares spm_clients_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_clients_csv)
    end

    it 'declares spm_enrollments_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_enrollments_csv)
    end

    it 'declares spm_enrollment_links_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_enrollment_links_csv)
    end

    it 'declares spm_episodes_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_episodes_csv)
    end

    it 'declares spm_returns_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_returns_csv)
    end

    it 'declares spm_bed_nights_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:spm_bed_nights_csv)
    end
  end

  describe 'generator registration' do
    it 'registers all four SPM generators in HudReportArchival.generator_registry' do
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

    it 'FY2020 config has exactly shared entries plus spm_clients_csv (no later-FY SPM tables)' do
      config = HudSpmReport::Generators::Fy2020::Generator.archival_csv_config(report_instance)
      expect(config.keys).to contain_exactly(
        :universe_members_csv,
        :spm_clients_csv,
        :report_cells_csv,
      )
    end

    it 'FY2023 config has exactly shared entries plus enrollment-based SPM tables (no clients or bed nights)' do
      config = HudSpmReport::Generators::Fy2023::Generator.archival_csv_config(report_instance)
      expect(config.keys).to contain_exactly(
        :universe_members_csv,
        :report_cells_csv,
        :spm_enrollment_links_csv,
        :spm_returns_csv,
        :spm_episodes_csv,
        :spm_enrollments_csv,
      )
    end

    it 'FY2024 config matches FY2023 key set (same attachment names; scopes differ by FY namespace)' do
      config = HudSpmReport::Generators::Fy2024::Generator.archival_csv_config(report_instance)
      expect(config.keys).to contain_exactly(
        :universe_members_csv,
        :report_cells_csv,
        :spm_enrollment_links_csv,
        :spm_returns_csv,
        :spm_episodes_csv,
        :spm_enrollments_csv,
      )
    end

    it 'FY2026 config adds spm_bed_nights_csv to the FY2023-style SPM tables' do
      config = HudSpmReport::Generators::Fy2026::Generator.archival_csv_config(report_instance)
      expect(config.keys).to contain_exactly(
        :universe_members_csv,
        :report_cells_csv,
        :spm_bed_nights_csv,
        :spm_enrollment_links_csv,
        :spm_returns_csv,
        :spm_episodes_csv,
        :spm_enrollments_csv,
      )
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
