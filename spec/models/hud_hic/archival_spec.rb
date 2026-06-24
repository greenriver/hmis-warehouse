###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudHic::Archival do
  let(:generators) do
    [HudHic::Generators::Hic::Fy2022::Generator]
  end

  before(:all) do
    _ = HudHic::Generators::Hic::Fy2022::Generator
  end

  describe 'attachment declarations on HudReports::ReportInstance' do
    it 'declares hic_projects_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:hic_projects_csv)
    end

    it 'declares hic_project_cocs_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:hic_project_cocs_csv)
    end

    it 'declares hic_inventories_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:hic_inventories_csv)
    end

    it 'declares hic_organizations_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:hic_organizations_csv)
    end

    it 'declares hic_funders_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:hic_funders_csv)
    end
  end

  describe 'generator registration' do
    it 'registers the HIC generator in HudReportArchival.generator_registry' do
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

    it 'config has exactly the expected attachment keys' do
      expected_keys = [
        :universe_members_csv,
        :hic_funders_csv,
        :hic_inventories_csv,
        :hic_project_cocs_csv,
        :hic_organizations_csv,
        :hic_projects_csv,
        :report_cells_csv,
      ]
      config = HudHic::Generators::Hic::Fy2022::Generator.archival_csv_config(report_instance)
      expect(config.keys).to contain_exactly(*expected_keys)
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

    it 'delete_order for universe_members_csv is 1 (deleted first)' do
      config = HudHic::Generators::Hic::Fy2022::Generator.archival_csv_config(report_instance)
      expect(config[:universe_members_csv][:delete_order]).to eq(1)
    end

    it 'delete_order for report_cells_csv is the highest (deleted last)' do
      config = HudHic::Generators::Hic::Fy2022::Generator.archival_csv_config(report_instance)
      max_order = config.values.map { |e| e[:delete_order] }.max
      expect(config[:report_cells_csv][:delete_order]).to eq(max_order)
    end
  end
end
