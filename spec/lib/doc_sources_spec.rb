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

    it 'reports a listed source that does not exist on disk' do
      write_doc(doc_path, sources: ['app/missing.rb'])

      expect(DocSources.check(@root)).to eq(["#{doc_path}: source `app/missing.rb` does not exist"])
    end

    it 'reports a source that has never been stamped' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])

      expect(DocSources.check(@root)).to eq(
        ["#{doc_path}: source `app/a.rb` is not in #{DocSources::MANIFEST}; run bin/doc_sources stamp"],
      )
    end

    it 'is clean right after a stamp' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/a.rb', 'app/b.rb'])
      DocSources.stamp(@root)

      expect(DocSources.check(@root)).to eq([])
    end

    it 'reports the doc and the source when a stamped source changes' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/a.rb', 'app/b.rb'])
      DocSources.stamp(@root)
      write('app/a.rb', 'x changed')

      expect(DocSources.check(@root)).to eq(
        ["#{doc_path}: source `app/a.rb` changed since last stamp; update the doc, then run bin/doc_sources stamp"],
      )
    end

    it 'reports a manifest entry no doc lists any more' do
      write('app/a.rb', 'x')
      write('app/gone.rb', 'z')
      write_doc(doc_path, sources: ['app/a.rb', 'app/gone.rb'])
      DocSources.stamp(@root)
      write_doc(doc_path, sources: ['app/a.rb'])

      expect(DocSources.check(@root)).to eq(
        ["#{DocSources::MANIFEST}: `app/gone.rb` is not listed by any doc; run bin/doc_sources stamp"],
      )
    end

    it 'reports each line-number citation in a doc body' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'], body: '`app/a.rb:12` `find`; `:40` `save`.')
      DocSources.stamp(@root)

      expect(DocSources.check(@root)).to contain_exactly(
        "#{doc_path}: cites line number `app/a.rb:12`; name the method or constant instead",
        "#{doc_path}: cites line number `:40`; name the method or constant instead",
      )
    end

    it 'does not treat paths without a line, clock times, or ratios as line citations' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'], body: '`app/a.rb` runs at 8:20 pm with a 1:1 mapping.')
      DocSources.stamp(@root)

      expect(DocSources.check(@root)).to eq([])
    end

    it 'skips a doc with no frontmatter, even one with a horizontal rule' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])
      write('docs/features/warehouse/plain.md', "# Plain\n\nIntro.\n\n---\n\nsources:\n  - app/missing.rb\n\n---\n")
      manifest = DocSources.stamp(@root)

      expect(manifest.keys).to eq(['app/a.rb'])
      expect(DocSources.check(@root)).to eq([])
    end

    it 'reports frontmatter that has no sources key' do
      write(doc_path, "---\ntitle: Thing\n---\n\n# Thing\n")

      expect(DocSources.check(@root)).to eq(["#{doc_path}: frontmatter missing `sources`"])
    end

    it 'reads docs at the top of docs/ and under docs/features/, and nowhere else in docs/' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc('docs/conventions.md', sources: ['app/a.rb'])
      write_doc('docs/architecture/x.md', sources: ['app/b.rb'])

      expect(DocSources.check(@root)).to eq(
        ['docs/conventions.md: source `app/a.rb` is not in docs/doc_sources_manifest.json; run bin/doc_sources stamp'],
      )
    end

    it 'reports line citations in a doc without frontmatter' do
      write('docs/features/warehouse/plain.md', "# Plain\n\nSee `app/a.rb:12`.\n")

      expect(DocSources.check(@root)).to eq(
        ['docs/features/warehouse/plain.md: cites line number `app/a.rb:12`; name the method or constant instead'],
      )
    end
  end

  describe '.stamp' do
    it 'writes one sha256 per unique source, sorted by path' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/b.rb', 'app/a.rb'])
      write_doc('docs/features/warehouse/other.md', sources: ['app/a.rb'])

      manifest = DocSources.stamp(@root)

      expect(manifest.keys).to eq(['app/a.rb', 'app/b.rb'])
      expect(manifest['app/a.rb']).to eq(Digest::SHA256.hexdigest('x'))
      expect(JSON.parse(File.read(File.join(@root, DocSources::MANIFEST)))).to eq(manifest)
    end
  end
end
