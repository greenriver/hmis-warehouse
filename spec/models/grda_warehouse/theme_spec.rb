###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Theme, type: :model do
  describe 'HMIS theme validation' do
    # cruft (non-HMIS themes that should not affect validation)
    let!(:wh_theme1) { create(:theme) }
    let!(:wh_theme2) { create(:theme, hmis_value: '') } # should be treated as non-HMIS theme

    before(:all) do
      ENV['CLIENT'] = 'test'
    end

    context 'when there are multiple HMIS themes with nil origin' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }

      it 'is invalid' do
        expect(theme1).to be_invalid
        expect(theme2).to be_invalid
      end
    end

    context 'when there are multiple HMIS themes with the same origin' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: 'test.dev') }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: 'test.dev') }

      it 'is invalid' do
        expect(theme1).to be_invalid
        expect(theme2).to be_invalid
      end
    end

    context 'when there are multiple HMIS themes with different origins' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: 'test1.dev') }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: 'test2.dev') }
      let!(:default_theme) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }

      it 'is valid' do
        expect(theme1).to be_valid
        expect(theme2).to be_valid
        expect(default_theme).to be_valid
      end

      it 'chooses specific theme for origin (test1.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin(theme1.hmis_origin)).to eq(theme1)
      end

      it 'chooses specific theme for origin (test2.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin(theme2.hmis_origin)).to eq(theme2)
      end

      it 'chooses default theme for origin (test3.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test3.dev')).to eq(default_theme)
      end
    end

    context 'when there is only a default theme' do
      let!(:default_theme) { create(:hmis_theme, hmis_origin: nil) }

      it 'chooses default theme for origin' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test1.dev')).to eq(default_theme)
      end
    end

    context 'when there is only a specific theme for test1.dev' do
      let!(:theme1) { create(:hmis_theme, hmis_origin: 'test1.dev') }

      it 'chooses specific theme for origin (test1.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test1.dev')).to eq(theme1)
      end
      it 'fails to find theme for different origin' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test2.dev')).to eq(nil)
      end
    end
  end

  describe '#sanitize_css' do
    let(:theme) { build(:theme) }

    shared_examples 'blocks script injection vectors' do
      it 'does not pass through javascript: URLs' do
        expect(theme.sanitize_css(raw_css)).not_to match(/javascript:/i)
      end

      it 'does not pass through expression(...)' do
        expect(theme.sanitize_css(raw_css)).not_to match(/expression\s*\(/i)
      end

      it 'does not pass through HTML script tags' do
        expect(theme.sanitize_css(raw_css)).not_to match(/<script/i)
      end

      it 'does not pass through @import rules' do
        expect(theme.sanitize_css(raw_css)).not_to match(/@import/i)
      end
    end

    context 'with legitimate theme CSS' do
      let(:raw_css) { ':root { --op-accent: #41596B; }' }

      it 'preserves the CSS unchanged' do
        expect(theme.sanitize_css(raw_css)).to eq(':root { --op-accent: #41596B; }')
      end
    end

    context 'with url(javascript:...) in a property value' do
      let(:raw_css) { ':root { --op-accent: red; } body { background: url(javascript:alert(1)); }' }

      include_examples 'blocks script injection vectors'
    end

    context 'with a closing-brace breakout and javascript: URL' do
      let(:raw_css) { ':root { --op-accent: red; } } body { background: url(javascript:alert(1)) } /*' }

      include_examples 'blocks script injection vectors'
    end

    context 'with expression(...)' do
      let(:raw_css) { 'body { width: expression(alert(1)); }' }

      include_examples 'blocks script injection vectors'
    end

    context 'with @import javascript:' do
      let(:raw_css) { '@import url(javascript:alert(1)); :root { --op-accent: red; }' }

      include_examples 'blocks script injection vectors'
    end

    context 'with legacy IE behavior and -moz-binding properties' do
      let(:raw_css) { 'body { behavior: url(evil.htc); -moz-binding: url(evil.xml#xss); }' }

      include_examples 'blocks script injection vectors'
    end

    context 'with a data: URI carrying HTML script markup' do
      let(:raw_css) { ':root { --op-accent: url(data:text/html,<script>alert(1)</script>); }' }

      include_examples 'blocks script injection vectors'
    end

    context 'with a </style><script> HTML breakout attempt' do
      let(:raw_css) { '</style><script>alert(1)</script><style> :root { --op-accent: red; }' }

      include_examples 'blocks script injection vectors'

      it 'still preserves the legitimate custom property' do
        expect(theme.sanitize_css(raw_css)).to include('--op-accent: red')
      end
    end
  end

  describe '.idp_theme_css' do
    before(:all) do
      ENV['CLIENT'] = 'test'
    end

    context 'when the theme has a configured accent color' do
      let!(:theme) { create(:hmis_theme, hmis_value: { 'palette' => { 'primary' => { 'main' => '#41596B' } } }) }

      it 'renders it as a CSS custom property' do
        expect(GrdaWarehouse::Theme.idp_theme_css).to eq(':root { --op-accent: #41596B; }')
      end
    end

    context 'when the theme has no palette configured' do
      let!(:theme) { create(:theme) }

      it 'returns an empty string' do
        expect(GrdaWarehouse::Theme.idp_theme_css).to eq('')
      end
    end

    context 'when hmis_value is an empty string (treated as "not an HMIS theme")' do
      let!(:theme) { create(:theme, hmis_value: '') }

      it 'returns an empty string rather than raising' do
        expect(GrdaWarehouse::Theme.idp_theme_css).to eq('')
      end
    end

    context 'when the configured value contains a CSS injection attempt' do
      let!(:theme) do
        create(
          :hmis_theme,
          hmis_value: {
            'palette' => {
              'primary' => {
                'main' => 'red; } body { background: url(javascript:alert(1)) } /*',
              },
            },
          },
        )
      end

      it 'strips the dangerous content rather than passing it through verbatim' do
        result = GrdaWarehouse::Theme.idp_theme_css

        expect(result).not_to include('javascript:')
        expect(result).not_to include('alert(')
      end
    end
  end
end
