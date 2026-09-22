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

# Keeps docs/domain-pack in step with the source files each doc describes.
# Stdlib only so bin/domain_pack and CI run it without booting Rails.
module DomainPack
  DOCS_DIR = 'docs/domain-pack'
  MANIFEST = "#{DOCS_DIR}/manifest.json".freeze
  REQUIRED_KEYS = ['title', 'summary', 'area', 'tags', 'sources'].freeze
  AREAS = ['conventions', 'authorization', 'roi', 'hmis', 'hud-reporting', 'warehouse'].freeze
  FRONTMATTER = /\A---\n(.*?)\n---\n/m
  FROZEN_STRING_LITERAL_LINE = /^# frozen_string_literal: true\n\n/
  REVIEW_REMINDER = 'If this failed, review the domain pack docs for the sources that changed ' \
    'and update their content to match the code — stamping only re-records digests, it does not ' \
    'confirm the docs are still accurate.'

  Doc = Struct.new(:path, :frontmatter, :errors, keyword_init: true)

  module_function

  def docs(root)
    root = Pathname(root)
    Dir.glob(root.join(DOCS_DIR, '**', '*.md').to_s).sort.filter_map do |abs|
      next if File.basename(abs) == 'README.md'

      parse_doc(Pathname(abs).relative_path_from(root).to_s, File.read(abs))
    end
  end

  def parse_doc(path, text)
    match = text.match(FRONTMATTER)
    return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: missing frontmatter"]) unless match

    begin
      frontmatter = YAML.safe_load(match[1]) || {}
    rescue Psych::SyntaxError
      return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: frontmatter is not valid YAML (quote values containing `: `)"])
    end

    errors = REQUIRED_KEYS.reject { |key| frontmatter.key?(key) }.map { |key| "#{path}: frontmatter missing `#{key}`" }
    errors << "#{path}: `area` must be one of #{AREAS.join(', ')}" if frontmatter.key?('area') && !AREAS.include?(frontmatter['area'])
    errors << "#{path}: `sources` must be a non-empty list" if frontmatter.key?('sources') && !(frontmatter['sources'].is_a?(Array) && frontmatter['sources'].any?)
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
    puts REVIEW_REMINDER
    ensure_backlinks(root, docs(root))
    manifest = sources(root).select { |source| root.join(source).file? }.to_h { |source| [source, digest(root, source)] }
    File.write(root.join(MANIFEST).to_s, "#{JSON.pretty_generate(manifest)}\n")
    manifest
  end

  def ensure_backlinks(root, all_docs)
    all_docs.each do |doc|
      Array(doc.frontmatter['sources']).select { |source| source.end_with?('.rb') }.each do |source|
        path = root.join(source)
        next unless path.file?

        backlink = "# See: #{doc.path}\n"
        content = path.read
        next if content.include?(backlink)
        next unless content.match?(FROZEN_STRING_LITERAL_LINE)

        path.write(content.sub(FROZEN_STRING_LITERAL_LINE) { "#{Regexp.last_match(0)}#{backlink}" })
      end
    end
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
          problems << "#{doc.path}: source `#{source}` is not in #{MANIFEST}; run bin/domain_pack stamp"
        elsif recorded != digest(root, source)
          problems << "#{doc.path}: source `#{source}` changed since last stamp; update the doc, then run bin/domain_pack stamp"
        end
      end
    end

    (manifest.keys - sources(root)).each do |orphan|
      problems << "#{MANIFEST}: `#{orphan}` is not listed by any doc; run bin/domain_pack stamp"
    end
    problems = problems.uniq
    puts REVIEW_REMINDER if problems.any?
    problems
  end
end
