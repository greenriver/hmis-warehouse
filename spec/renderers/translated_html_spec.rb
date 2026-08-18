###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TranslatedHtml do
  let(:markdown) { Redcarpet::Markdown.new(described_class) }

  describe '{{ }} translation substitution' do
    it 'substitutes {{Key}} with the stored translation' do
      Translation.create!(key: 'Greeting', text: 'Hello there')

      expect(markdown.render('{{Greeting}}')).to include('Hello there')
    end

    it 'escapes html in the substituted translation text' do
      Translation.create!(key: 'Payload', text: '<img src=x onerror=alert(1)>')

      html = markdown.render('{{Payload}}')
      expect(html).not_to include('<img')
      expect(html).to include('&lt;img')
    end

    it 'falls back to the key itself when no translation exists' do
      expect(markdown.render('{{Unknown Key}}')).to include('Unknown Key')
    end
  end

  describe 'markdown source' do
    it 'escapes raw html in the markdown source' do
      html = markdown.render('<script>alert(1)</script>')
      expect(html).not_to include('<script>')
      expect(html).to include('&lt;script&gt;')
    end

    it 'drops javascript: links' do
      html = markdown.render('[click me](javascript:alert(1))')
      expect(html).not_to include('href="javascript:')
    end

    it 'renders ordinary markdown' do
      expect(markdown.render('**bold**')).to include('<strong>bold</strong>')
    end
  end
end

RSpec.describe InlineHtml do
  let(:markdown) { Redcarpet::Markdown.new(described_class) }

  it 'does not wrap output in a paragraph tag' do
    expect(markdown.render('hello')).not_to include('<p>')
  end

  it 'inherits the escaping from TranslatedHtml' do
    html = markdown.render('<script>alert(1)</script>')
    expect(html).not_to include('<script>')
  end
end
