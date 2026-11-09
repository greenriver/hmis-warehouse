###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'pathname'
require 'yaml'

# Docs list the code files they describe in `sources:` frontmatter. `check` validates the
# frontmatter; `affected` and `missing_sources` feed the PR comment naming docs to re-read.
# Stdlib only so bin/doc_sources and CI run it without booting Rails.
module DocSources
  DOC_GLOBS = ['docs/*.md', 'docs/features/**/*.md'].freeze
  COMMENT_MARKER = '<!-- doc-sources -->'
  REQUIRED_KEYS = ['sources'].freeze
  FRONTMATTER = /\A---\n(.*?)\n---\n/m
  # `path.rb:12`, `path.rb:12-20`, or a bare `:40` continuing a citation. Line numbers drift
  # as code moves, so docs name methods and constants instead.
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
      rescue Psych::Exception
        return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: frontmatter is not valid YAML (quote values containing `: `)"])
      end

      return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: frontmatter must be a mapping"]) unless frontmatter.is_a?(Hash)

      errors = REQUIRED_KEYS.reject { |key| frontmatter.key?(key) }.map { |key| "#{path}: frontmatter missing `#{key}`" }
      invalid_sources = frontmatter.key?('sources') && !valid_sources?(frontmatter['sources'])
      return Doc.new(path: path, frontmatter: {}, errors: ["#{path}: `sources` must be a non-empty list of file paths"]) if invalid_sources
    end

    body.scan(LINE_CITATION).flatten.uniq.each do |citation|
      errors << "#{path}: cites line number `#{citation}`; name the method or constant instead"
    end
    Doc.new(path: path, frontmatter: frontmatter, errors: errors)
  end

  def valid_sources?(value)
    value.is_a?(Array) && value.any? && value.all?(String)
  end

  def check(root)
    docs(root).flat_map(&:errors).uniq
  end

  def affected(root, changed_paths)
    sources_by_doc(root) do |sources|
      sources & changed_paths
    end
  end

  def missing_sources(root)
    root = Pathname(root)
    sources_by_doc(root) do |sources|
      sources.reject { |source| root.join(source).file? }
    end
  end

  def comment_body(affected, missing)
    return '' if affected.empty? && missing.empty?

    sections = []
    if affected.any?
      sections << "### Docs that may need an update\n\n" \
                  "This PR changes code that these docs describe. Check that each still matches the code, and update it if not.\n\n" \
                  "#{doc_lines(affected)}\n"
    end
    if missing.any?
      sections << "#{affected.empty? ? "### Docs that may need an update\n\n" : ''}" \
                  "These docs list sources that no longer exist. Update their `sources:` frontmatter.\n\n" \
                  "#{doc_lines(missing)}\n"
    end
    "#{COMMENT_MARKER}\n#{sections.join("\n")}"
  end

  def doc_lines(by_doc)
    by_doc.map { |doc, sources| "- `#{doc}`: #{sources.map { |source| "`#{source}`" }.join(', ')}" }.join("\n")
  end

  # Yields each doc's sorted, unique sources; keeps docs where the block returns any.
  def sources_by_doc(root)
    docs(root).each_with_object({}) do |doc, result|
      matched = yield(Array(doc.frontmatter['sources']).uniq).sort
      result[doc.path] = matched if matched.any?
    end
  end
end
