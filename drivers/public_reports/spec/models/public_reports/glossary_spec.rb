###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::Glossary do
  let(:markdown) do
    <<~MARKDOWN
      Terms used on this page.

      ### Emergency Shelter (ES)
      Any facility whose primary purpose is to provide temporary shelter.

      A second paragraph of the same definition.

      ### ES / SO / SH / TH
      Emergency Shelter, Street Outreach, Safe Haven, Transitional Housing.
    MARKDOWN
  end

  subject(:glossary) { described_class.new(markdown) }

  it 'gives each heading an id built from its text' do
    ids = Nokogiri::HTML.fragment(glossary.html).css('dt').map { |h| h['id'] }
    expect(ids).to eq(['glossary-emergency-shelter-es', 'glossary-es-so-sh-th'])
  end

  it 'returns every paragraph up to the next heading as the definition' do
    expect(glossary.definition('Emergency Shelter (ES)')).to eq(
      'Any facility whose primary purpose is to provide temporary shelter. A second paragraph of the same definition.',
    )
    expect(glossary.definition('ES / SO / SH / TH')).to eq('Emergency Shelter, Street Outreach, Safe Haven, Transitional Housing.')
  end

  it 'puts each definition in a dd after its term and keeps intro text outside the list' do
    page = Nokogiri::HTML.fragment(glossary.html)

    expect(page.element_children.map(&:name)).to eq(['p', 'dl'])
    expect(page.element_children.first.text).to eq('Terms used on this page.')
    expect(page.css('dl > dt').map(&:text)).to eq(['Emergency Shelter (ES)', 'ES / SO / SH / TH'])
    expect(page.css('dl > dd').first.css('p').map(&:text)).to eq(
      ['Any facility whose primary purpose is to provide temporary shelter.', 'A second paragraph of the same definition.'],
    )
  end

  it 'returns nil for a term the glossary does not define' do
    expect(glossary.definition('Chronically Homeless')).to be_nil
  end

  it 'ids only the first of two headings with the same text' do
    glossary = described_class.new("### Sheltered\nFirst.\n\n### Sheltered\nSecond.\n")
    ids = Nokogiri::HTML.fragment(glossary.html).css('dt').map { |h| h['id'] }
    expect(ids).to eq(['glossary-sheltered', nil])
    expect(glossary.definition('Sheltered')).to eq('First.')
  end

  it 'keeps raw HTML in the markdown escaped' do
    glossary = described_class.new("### Term\n<script>alert(1)</script>\n")
    expect(glossary.html).not_to include('<script>')
    expect(glossary.html).to include('&lt;script&gt;')
  end

  it 'is blank when no glossary translation exists' do
    expect(described_class.from_translation).to be_blank
  end
end
