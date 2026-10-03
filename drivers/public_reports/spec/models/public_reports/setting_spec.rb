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

    it 'lets an override win only for that key, leaving the rest at their defaults' do
      setting = described_class.new(secondary_color: '#000000')

      expect([setting.theme[:secondary], setting.theme[:primary]]).to eq(['#000000', '#14558f'])
    end

    it 'uses heading_color when it is set' do
      expect(described_class.new(heading_color: '#003d79').theme[:heading]).to eq('#003d79')
    end

    it 'falls back the heading font to the body font when only the body font is set' do
      expect(described_class.new(font_family_0: 'Georgia, serif').theme[:font_heading]).to eq('Georgia, serif')
    end

    it 'replaces values that could break out of CSS with the defaults' do
      setting = described_class.new(
        font_family_0: 'x}</style><script>alert(1)</script>',
        font_url: 'https://fonts.example/a.css");}body{background:url("x',
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

    it 'uses a saved body font size and weight' do
      expect(described_class.new(font_size_0: '18px', font_weight_0: '300').theme.values_at(:font_size, :font_weight)).to eq(['18px', '300'])
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

    it 'accepts hex colors and blank values' do
      expect(described_class.new(summary_color: '#abc', secondary_color: '', race_color_2: '#AABBCC').valid?).to be(true)
    end
  end

  describe 'layouts/public_reports/_theme_css partial' do
    def render_theme(setting)
      report = PublicReports::StateLevelHomelessness.new
      allow(report).to receive(:settings).and_return(setting)
      ApplicationController.renderer.render(partial: 'layouts/public_reports/theme_css', assigns: { report: report })
    end

    it 'renders the primary color, body font size and weight, and the font @import' do
      html = render_theme(described_class.new(font_size_0: '18px'))

      expect(html).to include('--color-primary: #14558f', '--font-size-body: 18px', '--font-weight-body: 400', '@import url("https://fonts.googleapis.com/css2?family=Noto+Sans')
    end

    it 'never writes a closing style tag from a saved value' do
      html = render_theme(described_class.new(font_family_0: 'x}</style><script>alert(1)</script>'))

      expect(html.scan('</style>').size).to eq(1)
    end
  end
end
