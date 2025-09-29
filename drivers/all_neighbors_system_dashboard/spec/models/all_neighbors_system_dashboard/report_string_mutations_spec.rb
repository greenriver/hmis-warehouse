# frozen_string_literal: false

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

  describe '#publish_files method with gsub! operations' do
    it 'calls method that exercises gsub! operations for CSS processing' do
      # Test the gsub! operations from lines 327, 329: css.gsub!("url(...)", "url(...)")

      # Mock Rails assets to avoid complex setup
      asset = double('asset', to_s: "url(#{Rails.application.config.assets.prefix}/icons.ttf)", digest_path: 'icons-abc123.ttf')
      assets = double('assets')
      allow(assets).to receive(:[]).and_return(asset)
      allow(Rails.application).to receive(:assets).and_return(assets)
      allow(Rails.application.config).to receive_message_chain(:assets, :prefix).and_return('/assets')

      # Mock other assets that don't have gsub! operations
      ['icons.svg', 'icons.eot', 'icons.woff', 'icons.woff2'].each do |filename|
        mock_asset = double('asset', to_s: 'mock content', digest_path: "#{filename.split('.').first}-abc123.#{filename.split('.').last}")
        allow(assets).to receive(:[]).with(filename).and_return(mock_asset)
      end

      # Mock HTML generation
      allow(report).to receive(:as_html).and_return('<html></html>')

      # Mock JS asset paths
      allow(report).to receive(:per_page_js_asset_path).and_return('/path/to/js')
      allow(File).to receive(:read).and_return('js content')

      # This will exercise the gsub! operations on CSS content
      files = report.publish_files
      css_file = files.find { |f| f[:name] == 'application.css' }
      expect(css_file).to be_present

      # Call the content proc to exercise gsub! operations
      css_content = css_file[:content].call
      expect(css_content).to be_a(String)
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
