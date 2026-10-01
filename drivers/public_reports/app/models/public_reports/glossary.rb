###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The admin-edited 'Public Report Glossary' translation, rendered as markdown.
# Each heading is a term; the content up to the next heading is its definition.
module PublicReports
  class Glossary
    TRANSLATION_KEY = 'Public Report Glossary'
    HEADINGS = 'h1, h2, h3, h4, h5, h6'

    def self.from_translation
      text = Translation.translate(TRANSLATION_KEY)
      new(text == TRANSLATION_KEY ? '' : text)
    end

    def self.anchor(term)
      "glossary-#{term.parameterize}"
    end

    def initialize(markdown)
      @fragment = Nokogiri::HTML::DocumentFragment.parse(Redcarpet::Markdown.new(::TranslatedHtml).render(markdown.to_s))
      @definitions = {}
      @fragment.css(HEADINGS).each do |heading|
        id = self.class.anchor(heading.text)
        next if @definitions.key?(id)

        heading['id'] = id
        @definitions[id] = definition_after(heading)
      end
    end

    def blank?
      @fragment.text.blank?
    end

    # Markup comes from TranslatedHtml with escape_html on; Nokogiri only adds ids.
    def html
      @fragment.to_html.html_safe
    end

    def definition(term)
      @definitions[self.class.anchor(term)]
    end

    private def definition_after(heading)
      parts = []
      node = heading.next_element
      while node && !node.matches?(HEADINGS)
        parts << node.text.squish
        node = node.next_element
      end
      parts.join(' ').presence
    end
  end
end
