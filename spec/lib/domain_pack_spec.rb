###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require_relative '../../lib/domain_pack'

RSpec.describe DomainPack, type: :lib do
  around do |example|
    Dir.mktmpdir do |dir|
      @root = dir
      FileUtils.mkdir_p(File.join(dir, DomainPack::DOCS_DIR, 'warehouse'))
      example.run
    end
  end

  def write(rel, content)
    path = File.join(@root, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def write_doc(rel, sources:, area: 'warehouse')
    write(rel, <<~MD)
      ---
      title: Test doc
      summary: A doc.
      area: #{area}
      tags: [test]
      sources:
      #{sources.map { |s| "  - #{s}" }.join("\n")}
      ---

      ## Purpose
      Body.
    MD
  end

  let(:doc_path) { "#{DomainPack::DOCS_DIR}/warehouse/thing.md" }

  describe '.check' do
    it 'reports each missing required frontmatter key by name' do
      write(doc_path, "---\ntitle: Only title\n---\n\nbody\n")

      expect(DomainPack.check(@root)).to contain_exactly(
        "#{doc_path}: frontmatter missing `summary`",
        "#{doc_path}: frontmatter missing `area`",
        "#{doc_path}: frontmatter missing `tags`",
        "#{doc_path}: frontmatter missing `sources`",
      )
    end

    it 'reports a doc with no frontmatter block' do
      write(doc_path, "## Purpose\nno frontmatter\n")

      expect(DomainPack.check(@root)).to eq(["#{doc_path}: missing frontmatter"])
    end

    it 'reports frontmatter that is not valid YAML instead of raising' do
      write(doc_path, "---\ntitle: Bad\nsummary: Colon: space breaks it\n---\n\nbody\n")

      expect(DomainPack.check(@root)).to eq(["#{doc_path}: frontmatter is not valid YAML (quote values containing `: `)"])
    end

    it 'rejects an area outside the allowed list' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'], area: 'misc')
      DomainPack.stamp(@root)

      expect(DomainPack.check(@root)).to eq(
        ["#{doc_path}: `area` must be one of #{DomainPack::AREAS.join(', ')}"],
      )
    end

    it 'reports a listed source that does not exist on disk' do
      write_doc(doc_path, sources: ['app/missing.rb'])

      expect(DomainPack.check(@root)).to eq(["#{doc_path}: source `app/missing.rb` does not exist"])
    end

    it 'reports a source that has never been stamped' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])

      expect(DomainPack.check(@root)).to eq(
        ["#{doc_path}: source `app/a.rb` is not in #{DomainPack::MANIFEST}; run bin/domain_pack stamp"],
      )
    end

    it 'is clean right after a stamp' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/a.rb', 'app/b.rb'])
      DomainPack.stamp(@root)

      expect(DomainPack.check(@root)).to eq([])
    end

    it 'reports the doc and the source when a stamped source changes' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/a.rb', 'app/b.rb'])
      DomainPack.stamp(@root)
      write('app/a.rb', 'x changed')

      expect(DomainPack.check(@root)).to eq(
        ["#{doc_path}: source `app/a.rb` changed since last stamp; update the doc, then run bin/domain_pack stamp"],
      )
    end

    it 'reports a manifest entry no doc lists any more' do
      write('app/a.rb', 'x')
      write('app/gone.rb', 'z')
      write_doc(doc_path, sources: ['app/a.rb', 'app/gone.rb'])
      DomainPack.stamp(@root)
      write_doc(doc_path, sources: ['app/a.rb'])

      expect(DomainPack.check(@root)).to eq(
        ["#{DomainPack::MANIFEST}: `app/gone.rb` is not listed by any doc; run bin/domain_pack stamp"],
      )
    end

    it 'ignores README.md inside the pack' do
      write("#{DomainPack::DOCS_DIR}/README.md", "# Pack\nno frontmatter here\n")

      expect(DomainPack.check(@root)).to eq([])
    end

    it 'prints the review reminder when problems are found' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])

      expect { DomainPack.check(@root) }.to output(/#{Regexp.escape(DomainPack::REVIEW_REMINDER)}/).to_stdout
    end

    it 'does not print the review reminder when the pack is clean' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])
      DomainPack.stamp(@root)

      expect { DomainPack.check(@root) }.not_to output.to_stdout
    end
  end

  describe '.stamp' do
    it 'writes one sha256 per unique source, sorted by path' do
      write('app/a.rb', 'x')
      write('app/b.rb', 'y')
      write_doc(doc_path, sources: ['app/b.rb', 'app/a.rb'])
      write_doc("#{DomainPack::DOCS_DIR}/warehouse/other.md", sources: ['app/a.rb'])

      manifest = DomainPack.stamp(@root)

      expect(manifest.keys).to eq(['app/a.rb', 'app/b.rb'])
      expect(manifest['app/a.rb']).to eq(Digest::SHA256.hexdigest('x'))
      expect(JSON.parse(File.read(File.join(@root, DomainPack::MANIFEST)))).to eq(manifest)
    end

    it 'inserts a back-link comment into a referenced Ruby source after frozen_string_literal' do
      write('app/a.rb', "# frozen_string_literal: true\n\nclass A; end\n")
      write_doc(doc_path, sources: ['app/a.rb'])

      DomainPack.stamp(@root)

      expect(File.read(File.join(@root, 'app/a.rb'))).to eq(
        "# frozen_string_literal: true\n\n# See: #{doc_path}\nclass A; end\n",
      )
    end

    it 'does not duplicate the back-link when stamped twice' do
      write('app/a.rb', "# frozen_string_literal: true\n\nclass A; end\n")
      write_doc(doc_path, sources: ['app/a.rb'])

      DomainPack.stamp(@root)
      DomainPack.stamp(@root)

      expect(File.read(File.join(@root, 'app/a.rb')).scan("# See: #{doc_path}").size).to eq(1)
    end

    it 'adds one back-link per doc when two docs list the same Ruby source' do
      other_doc_path = "#{DomainPack::DOCS_DIR}/warehouse/other.md"
      write('app/a.rb', "# frozen_string_literal: true\n\nclass A; end\n")
      write_doc(doc_path, sources: ['app/a.rb'])
      write_doc(other_doc_path, sources: ['app/a.rb'])

      DomainPack.stamp(@root)

      content = File.read(File.join(@root, 'app/a.rb'))
      expect(content).to include("# See: #{doc_path}\n")
      expect(content).to include("# See: #{other_doc_path}\n")
    end

    it 'leaves non-Ruby sources untouched' do
      write('app/a.rb.erb', "# frozen_string_literal: true\n\n<%= 1 %>\n")
      write_doc(doc_path, sources: ['app/a.rb.erb'])

      DomainPack.stamp(@root)

      expect(File.read(File.join(@root, 'app/a.rb.erb'))).to eq("# frozen_string_literal: true\n\n<%= 1 %>\n")
    end

    it 'leaves a Ruby source without a frozen_string_literal anchor untouched' do
      write('app/a.rb', 'x')
      write_doc(doc_path, sources: ['app/a.rb'])

      DomainPack.stamp(@root)

      expect(File.read(File.join(@root, 'app/a.rb'))).to eq('x')
    end
  end
end
