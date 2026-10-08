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
        font_size: '1rem',
        font_weight: '400',
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

    it 'maps each theme column to its own token, including the heading font' do
      setting = described_class.new(
        font_url: 'https://fonts.googleapis.com/css2?family=Lato&display=swap',
        font_family_0: 'Georgia, serif',
        font_family_1: 'Lato, sans-serif',
        font_size_0: '18px',
        font_weight_0: '300',
        summary_color: '#000001',
        secondary_color: '#000002',
        heading_color: '#000003',
        text_color: '#000004',
        border_color: '#000005',
        surface_tint_color: '#000006',
        focus_color: '#000007',
        map_not_reporting_color: '#000008',
      )

      expect(setting.theme).to eq(
        font_url: 'https://fonts.googleapis.com/css2?family=Lato&display=swap',
        font_body: 'Georgia, serif',
        font_heading: 'Lato, sans-serif',
        font_size: '18px',
        font_weight: '300',
        primary: '#000001',
        secondary: '#000002',
        heading: '#000003',
        text: '#000004',
        border: '#000005',
        surface_tint: '#000006',
        focus: '#000007',
        not_reporting: '#000008',
      )
    end

    it 'falls back the heading font to the body font when only the body font is set' do
      expect(described_class.new(font_family_0: 'Georgia, serif').theme[:font_heading]).to eq('Georgia, serif')
    end

    it 'replaces values that could break out of CSS with the defaults' do
      setting = described_class.new(
        font_family_0: 'x}</style><script>alert(1)</script>',
        font_url: 'https://fonts.googleapis.com/css2?x");}body{display:none}',
        summary_color: '#14558f;}</style><script>',
        font_size_0: '1rem;}',
        font_weight_0: '400}',
      )

      expect(setting.theme.slice(:font_body, :font_url, :primary, :font_size, :font_weight)).to eq(
        font_body: '"Noto Sans", "Helvetica Neue", Arial, sans-serif',
        font_url: 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap',
        primary: '#14558f',
        font_size: '1rem',
        font_weight: '400',
      )
    end

    it 'replaces an unsafe chart color with the default for that slot' do
      setting = described_class.new(location_type_color_0: '#003d79" onmouseover="alert(1)')

      expect(setting.color(0, :location_type)).to eq('#003d79')
    end
  end

  describe 'validation' do
    it 'rejects a color that is not a CSS color and names the field' do
      setting = described_class.new(summary_color: 'red;}')

      expect(setting.valid?).to be(false)
      expect(setting.errors[:summary_color]).to eq(['is not a valid CSS value'])
    end

    it 'rejects an unsafe numbered or category chart color' do
      setting = described_class.new(color_3: '#000;}', race_color_2: 'x"')

      expect(setting.valid?).to be(false)
      expect(setting.errors.attribute_names).to contain_exactly(:color_3, :race_color_2)
    end

    it 'saves other changes when a stored value it is not changing is invalid' do
      setting = described_class.new(color_3: '#000;}')
      setting.save!(validate: false)

      expect(setting.update(summary_color: '#abcdef')).to be(true)
      expect(setting.update(color_3: '#000;}x')).to be(false)
    end

    it 'rejects a font stylesheet that is not on fonts.googleapis.com' do
      setting = described_class.new(font_url: 'https://fonts.example.com/a.css')

      expect(setting.valid?).to be(false)
      expect(setting.errors[:font_url]).to eq(['is not a valid CSS value'])
    end

    it 'accepts a protocol-relative Google Fonts URL as the font path but not one on another host' do
      google = described_class.new(font_url: '//fonts.googleapis.com/css?family=Lato')
      other = described_class.new(font_url: '//fonts.example.com/a.css')
      [google, other].each(&:validate)

      expect([google.errors[:font_url], google.font_path]).to eq([[], '//fonts.googleapis.com/css?family=Lato'])
      expect(other.errors[:font_url]).to eq(['is not a valid CSS value'])
    end

    it 'rejects a Google Fonts URL that carries quotes or parentheses' do
      setting = described_class.new(font_url: 'https://fonts.googleapis.com/css2?x");}body{display:none}')

      expect(setting.valid?).to be(false)
      expect(setting.errors.attribute_names).to contain_exactly(:font_url)
    end

    it 'accepts a Google Fonts stylesheet URL' do
      expect(described_class.new(font_url: 'https://fonts.googleapis.com/css2?family=Lato&display=swap').valid?).to be(true)
    end

    it 'accepts hex colors and blank values' do
      expect(described_class.new(summary_color: '#abc', secondary_color: '', race_color_2: '#AABBCC').valid?).to be(true)
    end
  end

  describe 'layouts/public_reports/_theme_css partial' do
    def render_theme(attributes)
      PublicReports::Setting.first_or_create.update_columns(attributes)
      ApplicationController.renderer.render(partial: 'layouts/public_reports/theme_css', assigns: { report: PublicReports::StateDashboard.new })
    end

    it 'renders the theme tokens, the font stack and the full font @import unescaped' do
      html = render_theme(font_size_0: '18px')

      expect(html).to include(
        '--color-primary: #14558f',
        '--font-size-body: 18px',
        '--font-weight-body: 400',
        '--font-body: "Noto Sans", "Helvetica Neue", Arial, sans-serif;',
        '@import url("https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap");',
      )
    end

    it 'never writes a closing style tag from a saved value' do
      html = render_theme(font_family_0: 'x}</style><script>alert(1)</script>')

      expect(html.scan('</style>').size).to eq(1)
    end
  end

  describe 'font constants' do
    it 'keeps the pre-redesign font defaults for the raw_public_report layout' do
      settings = described_class.new

      expect([settings.font_path, settings.font_family, settings.font_size, settings.font_weight]).to eq(
        [
          '//fonts.googleapis.com/css?family=Open+Sans:300,400,400italic,600,700|Open+Sans+Condensed:700|Poppins:400,300,500,700',
          'Poppins',
          '1rem',
          '300',
        ],
      )
    end
  end
end
