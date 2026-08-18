###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Renders markdown authored by end users or admins — project group notes, content pages,
# translation overrides. Raw HTML is either escaped or stripped (never emitted) and
# non-http(s) link schemes are dropped, so the result is safe to mark html_safe at the
# call site.
class SafeUserMarkdown
  # escape_html renders raw HTML as visible text instead of deleting it, which is usually
  # the more helpful default; pass strip_html: true where the caller wants raw HTML
  # removed instead (e.g. to match a previous filter_html-based renderer).
  ESCAPE_RENDER_OPTIONS = {
    escape_html: true,
    safe_links_only: true,
  }.freeze

  STRIP_RENDER_OPTIONS = {
    filter_html: true,
    safe_links_only: true,
  }.freeze

  MARKDOWN_EXTENSIONS = {
    autolink: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    space_after_headers: true,
  }.freeze

  def self.render(text, strip_html: false, **extensions)
    return ''.html_safe if text.blank?

    markdown(strip_html: strip_html, **extensions).render(text.to_s).html_safe
  end

  def self.markdown(strip_html: false, **extensions)
    render_options = strip_html ? STRIP_RENDER_OPTIONS : ESCAPE_RENDER_OPTIONS
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(render_options),
      MARKDOWN_EXTENSIONS.merge(extensions),
    )
  end
end
