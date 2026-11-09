###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'digest'
require 'json'
require 'pathname'
require 'yaml'

# Keeps docs in step with the code files they list in `sources:`.
# Stdlib only so bin/doc_sources and CI run it without booting Rails.
module DocSources
  DOC_GLOBS = ['docs/*.md', 'docs/features/**/*.md'].freeze
  MANIFEST = 'docs/doc_sources_manifest.json'
  REQUIRED_KEYS = ['sources'].freeze
  FRONTMATTER = /\A---\n(.*?)\n---\n/m
  # `path.rb:12`, `path.rb:12-20`, or a bare `:40` continuing a citation. Line numbers drift
  # without the source hash changing meaning, so docs name methods and constants instead.
  # ponytail: backtick spans only; a bare path:NNN in prose is not caught.
  LINE_CITATION = /`((?:[\w.\/-]+\.\w+)?:\d+(?:-\d+)?)`/

  Doc = Struct.new(:path, :frontmatter, :errors, keyword_init: true)

  module_function

  def docs(root)
    root = Pathname(root)
    paths = DOC_GLOBS.flat_map { |glob| Dir.glob(root.join(glob).to_s) }.uniq.sort
    paths.map do |abs|
      parse_doc(Pathname(abs).relative_path_from(root).to_s, File.read(abs))
    end
  end

  def parse_doc(path, text)
    match = text.match(FRONTMATTER)
    frontmatter = {}
    errors = []
    body = text

    if match
      body = text[match.end(0)..]
      begin
        frontmatter = YAML.safe_load(match[1]) || {}
      rescue Psych::SyntaxError
        return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: frontmatter is not valid YAML (quote values containing `: `)"])
      end

      errors = REQUIRED_KEYS.reject { |key| frontmatter.key?(key) }.map { |key| "#{path}: frontmatter missing `#{key}`" }
      errors << "#{path}: `sources` must be a non-empty list" if frontmatter.key?('sources') && !(frontmatter['sources'].is_a?(Array) && frontmatter['sources'].any?)
    end

    body.scan(LINE_CITATION).flatten.uniq.each do |citation|
      errors << "#{path}: cites line number `#{citation}`; name the method or constant instead"
    end
    Doc.new(path: path, frontmatter: frontmatter, errors: errors)
  end

  def sources(root)
    docs(root).flat_map { |doc| Array(doc.frontmatter['sources']) }.uniq.sort
  end

  def digest(root, source)
    Digest::SHA256.file(Pathname(root).join(source).to_s).hexdigest
  end

  def stamp(root)
    root = Pathname(root)
    manifest = sources(root).select { |source| root.join(source).file? }.to_h { |source| [source, digest(root, source)] }
    root.join(MANIFEST).dirname.mkpath
    File.write(root.join(MANIFEST).to_s, "#{JSON.pretty_generate(manifest)}\n")
    manifest
  end

  def check(root)
    root = Pathname(root)
    all_docs = docs(root)
    problems = all_docs.flat_map(&:errors)
    manifest_path = root.join(MANIFEST)
    manifest = manifest_path.exist? ? JSON.parse(manifest_path.read) : {}

    all_docs.each do |doc|
      Array(doc.frontmatter['sources']).each do |source|
        unless root.join(source).file?
          problems << "#{doc.path}: source `#{source}` does not exist"
          next
        end

        recorded = manifest[source]
        if recorded.nil?
          problems << "#{doc.path}: source `#{source}` is not in #{MANIFEST}; run bin/doc_sources stamp"
        elsif recorded != digest(root, source)
          problems << "#{doc.path}: source `#{source}` changed since last stamp; update the doc, then run bin/doc_sources stamp"
        end
      end
    end

    (manifest.keys - sources(root)).each do |orphan|
      problems << "#{MANIFEST}: `#{orphan}` is not listed by any doc; run bin/doc_sources stamp"
    end
    problems.uniq
  end
end
