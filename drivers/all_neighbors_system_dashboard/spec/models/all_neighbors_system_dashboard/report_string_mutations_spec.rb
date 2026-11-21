###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllNeighborsSystemDashboard::Report, type: :model do
  let(:report) do
    # Create a saved report to avoid database issues
    report = AllNeighborsSystemDashboard::Report.new
    allow(report).to receive(:persisted?).and_return(true)
    allow(report).to receive(:id).and_return(1)
    allow(report).to receive(:save).and_return(true)
    allow(report).to receive(:save!).and_return(true)
    report
  end

  describe '#publish_files' do
    let(:manifest_dir) { Dir.mktmpdir }
    let(:fonts) { ['icons.ttf', 'icons.svg', 'icons.eot', 'icons.woff', 'icons.woff2'] }
    let(:scripts) { ['bar.js', 'donut.js', 'filters.js', 'line.js', 'stack.js'] }

    before do
      assets = fonts.to_h { |font| [font, font.sub('.', '-0123.')] }
      scripts.each { |script| assets["all_neighbors_system_dashboard_#{script}"] = "all_neighbors_system_dashboard_#{script.sub('.', '-0123.')}" }
      assets['application.css'] = 'application-0123.css'
      assets.each_value { |digest_path| File.write(File.join(manifest_dir, digest_path), "content of #{digest_path}") }
      File.write(File.join(manifest_dir, 'application-0123.css'), fonts.map { |font| "@font-face{src:url(/assets/#{font.sub('.', '-0123.')}?v=1)}" }.join)
      File.write(File.join(manifest_dir, ".sprockets-manifest-#{'0' * 32}.json"), { files: {}, assets: assets }.to_json)

      allow(Rails.application).to receive(:assets_manifest).and_return(Sprockets::Manifest.new(nil, manifest_dir))
      allow(Rails.application).to receive(:assets).and_return(nil)
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('staging'))
    end

    after { FileUtils.remove_entry(manifest_dir) }

    it 'points the published stylesheet at the published font files' do
      css = report.publish_files.find { |f| f[:name] == 'application.css' }[:content].call

      expect(css).to eq(fonts.map { |font| "@font-face{src:url(#{font}?v=1)}" }.join)
    end

    it 'publishes each font file from its own precompiled asset' do
      published = report.publish_files.select { |f| f[:name].in?(fonts) }.to_h { |f| [f[:name], f[:content].call] }

      expect(published).to eq(fonts.to_h { |font| [font, "content of #{font.sub('.', '-0123.')}"] })
    end

    it 'publishes each chart script from its own precompiled asset' do
      published = report.publish_files.select { |f| f[:name].in?(scripts) }.to_h { |f| [f[:name], f[:content].call] }

      expect(published).to eq(scripts.to_h { |script| [script, "content of all_neighbors_system_dashboard_#{script.sub('.', '-0123.')}"] })
    end
  end

  describe 'class instantiation' do
    it 'creates new instance without error' do
      # Test that the class can be instantiated
      new_report = AllNeighborsSystemDashboard::Report.new

      expect(new_report).to be_a(AllNeighborsSystemDashboard::Report)
    end
  end
end
