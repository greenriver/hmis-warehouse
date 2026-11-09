###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require_relative '../../lib/doc_sources'

RSpec.describe DocSources, type: :lib do
  around do |example|
    Dir.mktmpdir do |dir|
      @root = dir
      example.run
    end
  end

  def write(rel, content)
    path = File.join(@root, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def write_doc(rel, sources:, body: 'Body.')
    write(rel, "---\nsources:\n#{sources.map { |s| "  - #{s}" }.join("\n")}\n---\n\n# Thing\n\n#{body}\n")
  end

  let(:doc_path) { 'docs/features/warehouse/thing.md' }

  describe '.check' do
    it 'reports frontmatter that is not valid YAML instead of raising' do
      write(doc_path, "---\ntitle: Bad\nsummary: Colon: space breaks it\n---\n\nbody\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: frontmatter is not valid YAML (quote values containing `: `)"])
    end

    it 'reports frontmatter that parses to something other than a mapping' do
      write(doc_path, "---\nFirst paragraph.\n---\n\n# Thing\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: frontmatter must be a mapping"])
    end

    it 'reports an unquoted date in frontmatter as invalid YAML instead of raising' do
      write(doc_path, "---\nupdated: 2026-11-09\nsources:\n  - app/a.rb\n---\n\n# Thing\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: frontmatter is not valid YAML (quote values containing `: `)"])
    end

    it 'reports a sources entry that is not a string instead of raising' do
      write(doc_path, "---\nsources:\n  - app/a.rb\n  - 42\n---\n\n# Thing\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: `sources` must be a non-empty list of file paths"])
    end

    it 'does not report a listed source that does not exist on disk' do
      write_doc(doc_path, sources: ['app/missing.rb'])

      expect(DocSources.check(@root)).to eq([])
    end

    it 'reports each line-number citation in a doc body' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'], body: '`app/a.rb:12` `find`; `:40` `save`.')
      expect(DocSources.check(@root)).to contain_exactly(
        "#{doc_path}: cites line number `app/a.rb:12`; name the method or constant instead",
        "#{doc_path}: cites line number `:40`; name the method or constant instead",
      )
    end

    it 'does not treat paths without a line, clock times, or ratios as line citations' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'], body: '`app/a.rb` runs at 8:20 pm with a 1:1 mapping.')
      expect(DocSources.check(@root)).to eq([])
    end

    it 'skips a doc with no frontmatter, even one with a horizontal rule' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])
      write('docs/features/warehouse/plain.md', "# Plain\n\nIntro.\n\n---\n\nsources:\n  - app/missing.rb\n\n---\n")

      expect(DocSources.check(@root)).to eq([])
    end

    it 'reports frontmatter that has no sources key' do
      write(doc_path, "---\ntitle: Thing\n---\n\n# Thing\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: frontmatter missing `sources`"])
    end

    it 'reads docs at the top of docs/ and under docs/features/, and nowhere else in docs/' do
      write('docs/conventions.md', "---\ntitle: Top\n---\n")
      write('docs/features/warehouse/deep.md', "---\ntitle: Deep\n---\n")
      write('docs/architecture/x.md', "---\ntitle: Arch\n---\n")

      expect(DocSources.check(@root)).to contain_exactly(
        'docs/conventions.md: frontmatter missing `sources`',
        'docs/features/warehouse/deep.md: frontmatter missing `sources`',
      )
    end

    it 'reports line citations in a doc without frontmatter' do
      write('docs/features/warehouse/plain.md', "# Plain\n\nSee `app/a.rb:12`.\n")

      expect(DocSources.check(@root)).to eq(
        ['docs/features/warehouse/plain.md: cites line number `app/a.rb:12`; name the method or constant instead'],
      )
    end
  end

  describe '.affected' do
    let(:other_path) { 'docs/features/warehouse/other.md' }

    it 'lists the listed sources that changed, sorted, and omits docs and sources that did not' do
      write_doc(doc_path, sources: ['app/b.rb', 'app/a.rb', 'app/c.rb'])
      write_doc(other_path, sources: ['app/d.rb'])

      expect(DocSources.affected(@root, ['app/b.rb', 'app/a.rb', 'app/unlisted.rb'])).to eq(
        { doc_path => ['app/a.rb', 'app/b.rb'] },
      )
    end

    it 'lists every doc that lists a changed source' do
      write_doc(doc_path, sources: ['app/a.rb'])
      write_doc(other_path, sources: ['app/a.rb'])

      expect(DocSources.affected(@root, ['app/a.rb'])).to eq(
        { other_path => ['app/a.rb'], doc_path => ['app/a.rb'] },
      )
      expect(DocSources.affected(@root, ['app/a.rb']).keys).to eq([other_path, doc_path])
    end

    it 'returns an empty hash when nothing listed changed' do
      write_doc(doc_path, sources: ['app/a.rb'])

      expect(DocSources.affected(@root, ['app/z.rb'])).to eq({})
    end
  end

  describe '.missing_sources' do
    it 'lists listed sources that are not files, sorted, and omits docs with none missing' do
      write('app/present.rb', 'x')
      write('app/dir/keep.rb', 'x')
      write_doc(doc_path, sources: ['app/z_gone.rb', 'app/present.rb', 'app/a_gone.rb', 'app/dir'])
      write_doc('docs/features/warehouse/ok.md', sources: ['app/present.rb'])

      expect(DocSources.missing_sources(@root)).to eq(
        { doc_path => ['app/a_gone.rb', 'app/dir', 'app/z_gone.rb'] },
      )
    end
  end

  describe '.comment_body' do
    it 'is empty when there is nothing to report' do
      expect(DocSources.comment_body({}, {})).to eq('')
    end

    it 'has a section for affected docs and one for missing sources' do
      body = DocSources.comment_body(
        { 'docs/features/a.md' => ['app/one.rb', 'app/two.rb'], 'docs/features/b.md' => ['app/one.rb'] },
        { 'docs/features/x.md' => ['app/old/path.rb'] },
      )

      expect(body).to eq(<<~MD)
        <!-- doc-sources -->
        ### Docs that may need an update

        This PR changes code that these docs describe. Check that each still matches the code, and update it if not.

        - `docs/features/a.md`: `app/one.rb`, `app/two.rb`
        - `docs/features/b.md`: `app/one.rb`

        These docs list sources that no longer exist. Update their `sources:` frontmatter.

        - `docs/features/x.md`: `app/old/path.rb`
      MD
    end

    it 'has only the affected section when no sources are missing' do
      body = DocSources.comment_body({ 'docs/features/a.md' => ['app/one.rb'] }, {})

      expect(body).to eq(<<~MD)
        <!-- doc-sources -->
        ### Docs that may need an update

        This PR changes code that these docs describe. Check that each still matches the code, and update it if not.

        - `docs/features/a.md`: `app/one.rb`
      MD
    end

    it 'has only the missing section when no listed source changed' do
      body = DocSources.comment_body({}, { 'docs/features/x.md' => ['app/old/path.rb'] })

      expect(body).to eq(<<~MD)
        <!-- doc-sources -->
        ### Docs that may need an update

        These docs list sources that no longer exist. Update their `sources:` frontmatter.

        - `docs/features/x.md`: `app/old/path.rb`
      MD
    end
  end
end
