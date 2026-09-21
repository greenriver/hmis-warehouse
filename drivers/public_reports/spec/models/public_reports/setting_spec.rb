###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::Setting, type: :model do
  describe '#theme' do
    it 'returns the MA defaults when no columns are set' do
      setting = described_class.new
      expect(setting.theme).to eq(
        font_url: 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap',
        font_body: '"Noto Sans", "Helvetica Neue", Arial, sans-serif',
        font_heading: '"Noto Sans", "Helvetica Neue", Arial, sans-serif',
        primary: '#14558f',
        secondary: '#2d6a46',
        heading: '#1b1b1b',
        text: '#262626',
        border: '#cccccc',
        surface_tint: '#e7eef4',
        focus: '#0088ff',
        not_reporting: '#EDEDED',
      )
    end

    it 'lets an override win only for that key, leaving the rest at their defaults' do
      setting = described_class.new(secondary_color: '#000000')

      expect(setting.theme[:secondary]).to eq('#000000')
      expect(setting.theme[:primary]).to eq('#14558f')
    end

    it 'falls back heading to the ink color when heading_color is unset' do
      setting = described_class.new
      expect(setting.theme[:heading]).to eq('#1b1b1b')
    end

    it 'uses heading_color when it is set' do
      setting = described_class.new(heading_color: '#003d79')
      expect(setting.theme[:heading]).to eq('#003d79')
    end
  end

  describe 'layouts/public_reports/_theme_css partial' do
    it 'renders the primary color variable and the font @import' do
      report = PublicReports::StateLevelHomelessness.new
      html = ApplicationController.renderer.render(
        partial: 'layouts/public_reports/theme_css',
        assigns: { report: report },
      )

      expect(html).to include('--color-primary: #14558f')
      expect(html).to include('@import url("https://fonts.googleapis.com/css2?family=Noto+Sans')
    end
  end
end
