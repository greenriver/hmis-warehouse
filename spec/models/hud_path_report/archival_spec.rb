###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudPathReport::Archival do
  let(:generators) do
    [
      HudPathReport::Generators::Fy2020::Generator,
      HudPathReport::Generators::Fy2021::Generator,
      HudPathReport::Generators::Fy2024::Generator,
      HudPathReport::Generators::Fy2026::Generator,
    ]
  end

  before(:all) do
    _ = HudPathReport::Generators::Fy2020::Generator
    _ = HudPathReport::Generators::Fy2021::Generator
    _ = HudPathReport::Generators::Fy2024::Generator
    _ = HudPathReport::Generators::Fy2026::Generator
  end

  describe 'attachment declarations on HudReports::ReportInstance' do
    it 'declares path_clients_csv attachment' do
      expect(HudReports::ReportInstance.new).to respond_to(:path_clients_csv)
    end
  end

  describe 'generator registration' do
    it 'registers all PATH generators in HudReportArchival.generator_registry' do
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
      expected_keys = [:universe_members_csv, :path_clients_csv, :report_cells_csv]
      generators.each do |gen|
        config = gen.archival_csv_config(report_instance)
        expect(config.keys).to(
          contain_exactly(*expected_keys),
          "#{gen.name} config keys mismatch",
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
