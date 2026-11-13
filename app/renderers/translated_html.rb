###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TranslatedHtml < Redcarpet::Render::HTML
  TRANSLATION_PATTERN = /{{(.*?)}}/

  # Translation text is editable by anyone with can_edit_translations and is rendered on
  # public, unauthenticated report pages, so treat both the markdown source and the {{ }}
  # substitutions as untrusted.
  DEFAULT_RENDER_OPTIONS = {
    escape_html: true,
    safe_links_only: true,
  }.freeze

  def initialize(extensions = {})
    super(DEFAULT_RENDER_OPTIONS.merge(extensions))
  end

  # Converts {{Some Key}} to its Translation. This runs after Redcarpet has produced the
  # final HTML, so the text is spliced straight into the document — escape_html and
  # filter_html do not apply here and the escaping has to be explicit.
  def postprocess(html)
    html.gsub(TRANSLATION_PATTERN) do
      ERB::Util.html_escape(Translation.translate(Regexp.last_match(1))).to_s
    end
  end
end
