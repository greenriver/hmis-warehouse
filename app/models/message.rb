###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# email message stowed in database
class Message < ApplicationRecord
  SCHEDULES = ['immediate', 'daily'].freeze

  belongs_to :user
  scope :sent, ->(time = DateTime.current) { where arel_table[:sent_at].lteq time }
  scope :unsent, -> { where sent_at: nil }
  scope :seen, ->(time = DateTime.current) { where arel_table[:seen_at].lteq time }
  scope :unseen, -> { where seen_at: nil }
  scope :before, ->(time) { where arel_table[:created_at].lt time }

  # support presentation of html or text messages in html or text format
  def sanitized_body(render_as:)
    raise ArgumentError, "format not supported: \"#{render_as}\"" unless render_as.in?([:text, :html])

    html ? sanitized_html(body, format: render_as) : sanitized_text(body, format: render_as)
  end

  def opened?
    seen_at.present?
  end

  # called on text messages only
  private def sanitized_text(raw, format:)
    return raw if format == :text

    stripped = ActionController::Base.helpers.strip_tags(raw)
    linked = make_text_links_clickable(stripped)
    formatted = ActionController::Base.helpers.simple_format(linked)
    sanitizer.sanitize(formatted).html_safe
  end

  # called on html messages only
  private def sanitized_html(raw, format:)
    return Nokogiri(raw).text if format == :text

    # message body maybe html document. Extract html body content
    inner = Nokogiri(raw).at('body')&.children&.map(&:to_s)&.join
    inner ? sanitizer.sanitize(inner).html_safe : ''
  end

  # Wraps http/https URLs in <a> tags
  private def make_text_links_clickable(text)
    uri_rgx = URI::DEFAULT_PARSER.make_regexp(['http', 'https'])
    text.gsub(uri_rgx) { |url| %(<a href="#{url}">#{url}</a>) }
  end

  private def sanitizer
    Rails::Html::SafeListSanitizer.new
  end
end
