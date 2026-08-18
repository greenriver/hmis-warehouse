###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SafeUserMarkdown do
  describe '.render' do
    it 'escapes raw html in the source' do
      expect(described_class.render('<b>bold</b>')).to include('&lt;b&gt;bold&lt;/b&gt;')
    end

    it 'escapes script tags' do
      expect(described_class.render('<script>alert(1)</script>')).not_to include('<script>')
    end

    it 'drops javascript: links' do
      html = described_class.render('[click me](javascript:alert(1))')
      expect(html).not_to include('href="javascript:')
    end

    it 'renders ordinary markdown' do
      expect(described_class.render('**bold**')).to include('<strong>bold</strong>')
    end

    it 'returns an empty html_safe string for blank input' do
      expect(described_class.render(nil)).to eq('')
      expect(described_class.render(nil)).to be_html_safe
      expect(described_class.render('')).to eq('')
    end

    it 'returns html_safe output' do
      expect(described_class.render('hello')).to be_html_safe
    end
  end

  describe '.render with strip_html: true' do
    it 'strips raw html instead of escaping it' do
      html = described_class.render('<b>bold</b>', strip_html: true)
      expect(html).not_to include('<b>')
      expect(html).not_to include('&lt;b&gt;')
    end

    it 'strips script tags' do
      html = described_class.render('<script>alert(1)</script>', strip_html: true)
      expect(html).not_to include('<script>')
      expect(html).not_to include('&lt;script&gt;')
    end

    it 'still drops javascript: links' do
      html = described_class.render('[click me](javascript:alert(1))', strip_html: true)
      expect(html).not_to include('href="javascript:')
    end

    it 'still renders ordinary markdown' do
      expect(described_class.render('**bold**', strip_html: true)).to include('<strong>bold</strong>')
    end
  end
end
