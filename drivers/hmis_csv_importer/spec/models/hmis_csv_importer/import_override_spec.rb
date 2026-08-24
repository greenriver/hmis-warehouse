###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::ImportOverride, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }

  def render_markdown(text)
    Redcarpet::Markdown.new(TranslatedHtml).render(text)
  end

  describe '#describe_overall' do
    # Test design: Tier 3 — admin-entered replacement_value is spliced into the
    # markdown source before Redcarpet parses it. Asserts the raw source carries
    # the backslash-escaped characters and that rendering it produces the link
    # text literally rather than an injected <a> tag.
    it 'escapes markdown-significant characters in replacement_value' do
      override = create(
        :import_override,
        data_source: data_source,
        file_name: 'Project.csv',
        replaces_column: 'FirstName',
        replacement_value: '[click here](http://evil.example)',
      )

      description = override.describe_overall
      expect(description).to include('\\[click here\\]\\(http://evil\\.example\\)')

      html = render_markdown(description)
      expect(html).not_to include('<a href')
      expect(html).to include('[click here](http://evil.example)')
    end

    # Test design: Tier 2 — regression for a nil-check bug where the ':NULL:'
    # branch's re-check ran against the already-reassigned local variable
    # instead of the original describe_with result, which would re-wrap
    # 'will be **removed**' a second time.
    it 'describes a removal without double-wrapping when replacement_value is :NULL:' do
      override = create(
        :import_override,
        data_source: data_source,
        file_name: 'Project.csv',
        replaces_column: 'FirstName',
        replacement_value: ':NULL:',
      )

      expect(override.describe_overall).to eq('In Project.csv, **FirstName** will be will be **removed** for **all records** in the data source.')
    end
  end

  describe '#describe_created' do
    # Test design: Tier 3 — creator.name_with_email is spliced into `_..._`
    # markdown emphasis. An unescaped underscore in the name would close the
    # emphasis early; escaping keeps the name literal and the emphasis intact.
    it 'escapes markdown-significant characters in the creator name' do
      creator = create(:user)
      allow(creator).to receive(:name_with_email).and_return('Jane_Doe*Admin')
      override = create(
        :import_override,
        data_source: data_source,
        file_name: 'Project.csv',
        replaces_column: 'FirstName',
        replacement_value: 'value',
        creator: creator,
      )

      description = override.describe_created
      expect(description).to include('Jane\\_Doe\\*Admin')

      html = render_markdown(description)
      expect(html).to include('<em>Jane_Doe*Admin</em>')
    end
  end

  describe '#describe_apply' do
    # Test design: Tier 3 regression — describe_apply feeds a plain-text flash
    # message (see import_overrides_controller#apply), never markdown, so its
    # output must stay byte-for-byte unescaped.
    it 'does not escape markdown-significant characters' do
      override = create(
        :import_override,
        data_source: data_source,
        file_name: 'Project.csv',
        replaces_column: 'FirstName',
        replacement_value: '[click here](http://evil.example)',
      )

      expect(override.describe_apply).to eq('FirstName has been replaced with [click here](http://evil.example) for all associated records.')
    end
  end

  describe '#describe_when' do
    # Test design: Tier 3 — matched_hud_key and replaces_value_language are
    # only escaped when the markdown: true context is requested; describe_apply
    # and the plain-text table cell (_table.haml) rely on the default staying
    # unescaped.
    it 'escapes matched_hud_key and replaces_value_language only when markdown: true' do
      file_name = HmisCsvImporter::ImportOverride.available_files.first
      override = create(
        :import_override,
        data_source: data_source,
        file_name: file_name,
        replaces_column: 'FirstName',
        replacement_value: 'value',
        matched_hud_key: 'Key*Name',
        replaces_value: 'Val_ue',
      )
      hud_key = override.associated_class.hud_key

      expect(override.describe_when).to eq("#{hud_key} is Key*Name and FirstName is Val_ue")
      expect(override.describe_when(markdown: true)).to eq("#{hud_key} is Key\\*Name and FirstName is Val\\_ue")
    end
  end
end
