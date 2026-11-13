###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::LsasController, type: :controller do
  let(:user) { create(:user) }

  before(:each) do
    sign_in user
  end

  # Pin the version table so these examples keep testing the active/inactive rule
  # rather than whichever fiscal years happen to be listed in the controller.
  def stub_report_versions(**versions)
    table = versions.map { |slug, active| [slug.to_s.upcase, { slug: slug, active: active }] }.to_h
    allow(controller).to receive(:available_report_versions).and_return(table)
  end

  describe '#report_class' do
    it 'uses the version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2027' })

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2027::Lsa)
    end

    it 'honors an earlier version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2026' })

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2026::Lsa)
    end

    it 'falls back to the newest active version when none is chosen' do
      stub_report_versions(fy2026: true, fy2027: true)
      controller.params = ActionController::Parameters.new({})

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2027::Lsa)
    end

    # The LSA fiscal year is independent of the HUD CSV data standard version; tying the
    # two together kept FY 2027 from running while the current CSV standard was 2026.
    it 'ignores HudHelper.current_version when choosing the default' do
      stub_report_versions(fy2026: false, fy2027: true)
      allow(HudHelper).to receive(:current_version).and_return('2026')
      controller.params = ActionController::Parameters.new({})

      expect(controller.report_class).to eq(HudLsa::Generators::Fy2027::Lsa)
    end
  end

  describe '#default_report_version' do
    it 'is the last version marked active' do
      stub_report_versions(fy2024: false, fy2026: true, fy2027: true)

      expect(controller.default_report_version).to eq(:fy2027)
    end

    it 'skips newer versions that are not yet active' do
      stub_report_versions(fy2024: false, fy2026: true, fy2027: false)

      expect(controller.default_report_version).to eq(:fy2026)
    end
  end

  describe '#report_name' do
    it 'matches the version chosen in the filter' do
      controller.params = ActionController::Parameters.new(filter: { report_version: 'fy2027' })

      expect(controller.send(:report_name)).to eq('Longitudinal System Analysis - FY 2027')
    end
  end
end
