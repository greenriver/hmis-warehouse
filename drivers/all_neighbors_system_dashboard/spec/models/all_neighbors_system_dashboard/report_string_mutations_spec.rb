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

    before do
      assets = fonts.to_h { |font| [font, font.sub('.', '-0123.')] }
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

    it 'publishes the precompiled font files' do
      ttf = report.publish_files.find { |f| f[:name] == 'icons.ttf' }[:content].call

      expect(ttf).to eq('content of icons-0123.ttf')
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
