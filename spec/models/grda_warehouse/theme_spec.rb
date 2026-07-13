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

    # active_theme keys off ENV['CLIENT']; set it per-example and restore the
    # original afterward so we don't leak process state into other spec files.
    around do |example|
      original_client = ENV['CLIENT']
      ENV['CLIENT'] = 'test'
      example.run
    ensure
      ENV['CLIENT'] = original_client
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

      it 'does not leave a literal "<" character anywhere in the output' do
        expect(theme.sanitize_css(raw_css)).not_to include('<')
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

    context 'with an unterminated "</style" breakout (no ">" anywhere in the input)' do
      # HTML5's tokenizer ends a RAWTEXT <style> element as soon as it sees "</style"
      # followed by a tag-name-terminating character (whitespace, "/", ">", or EOF) --
      # a closing ">" is not required to trigger the state transition. A regex that
      # requires a literal ">" to complete a match (like the original `/<[^>]*>/`)
      # never matches, and therefore never strips, a "</style" with no ">" anywhere
      # later in the string.
      let(:raw_css) { ':root { --op-accent: red; } body { content: "</style"; }' }

      include_examples 'blocks script injection vectors'

      it 'strips the unterminated "</style" sequence' do
        expect(theme.sanitize_css(raw_css)).not_to match(/<\/style/i)
      end
    end

    context 'with a nested-bracket reconstruction attempt (classic incomplete multi-character sanitization bypass)' do
      # A single-pass regex that removes one multi-character sequence can be defeated
      # by nesting: removing the inner match splices the surrounding fragments back
      # together into the original dangerous sequence. This is CodeQL's
      # rb/incomplete-multi-character-sanitization example almost verbatim. Our
      # trailing `.gsub('<', '')` sidesteps the whole class of bug, since it removes
      # every "<" unconditionally rather than trying to match a complete sequence.
      let(:raw_css) { ':root { --op-accent: red; } body { content: "<scrip<script>is removed</script>t>alert(123)</script>"; } ' }

      include_examples 'blocks script injection vectors'
    end

    context 'with a legitimate child-combinator selector' do
      let(:raw_css) { ':root { --op-accent: red; } div > p { --op-accent: blue; }' }

      it 'preserves the ">" combinator (only "<" is stripped, not ">")' do
        expect(theme.sanitize_css(raw_css)).to match(/div\s*>\s*p/)
      end
    end

    context 'with HTML-entity-encoded angle brackets in a value' do
      # Entities are never decoded downstream: `render plain:` serves this as a
      # standalone text/css response, and Haml's `:plain` filter inlines it inside a
      # <style> element, which the HTML5 tokenizer parses in RAWTEXT mode (no
      # character-reference decoding there). CSS itself doesn't decode HTML entities
      # either, so "&lt;"/"&gt;" can never become a literal "<"/">" in the browser --
      # this is inert text, not a sanitization gap.
      let(:raw_css) { ':root { --op-accent: "&lt;script&gt;"; }' }

      it 'leaves the entity-encoded text untouched' do
        expect(theme.sanitize_css(raw_css)).to include('&lt;script&gt;')
      end
    end
  end

  describe '.idp_theme_css' do
    # active_theme keys off ENV['CLIENT']; set it per-example and restore the
    # original afterward so we don't leak process state into other spec files.
    around do |example|
      original_client = ENV['CLIENT']
      ENV['CLIENT'] = 'test'
      example.run
    ensure
      ENV['CLIENT'] = original_client
    end

    context 'when the theme has custom CSS configured' do
      let!(:theme) { create(:theme, css_file_contents: ':root { --op-accent: #41596B; }') }

      it 'returns the sanitized CSS' do
        expect(GrdaWarehouse::Theme.idp_theme_css).to eq(':root { --op-accent: #41596B; }')
      end
    end

    context 'when the theme has no custom CSS configured' do
      let!(:theme) { create(:theme) }

      it 'matches Theme.css_file_contents (falls back to the default stylesheet, same as the main app)' do
        expect(GrdaWarehouse::Theme.idp_theme_css).to eq(GrdaWarehouse::Theme.css_file_contents)
      end
    end

    context 'when the configured CSS contains an injection attempt' do
      let!(:theme) { create(:theme, css_file_contents: ':root { --op-accent: red; } } body { background: url(javascript:alert(1)) } /*') }

      it 'strips the dangerous content rather than passing it through verbatim' do
        result = GrdaWarehouse::Theme.idp_theme_css

        expect(result).not_to include('javascript:')
        expect(result).not_to include('alert(')
      end
    end
  end
end
