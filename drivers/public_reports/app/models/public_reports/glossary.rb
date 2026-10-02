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
      fragment = Nokogiri::HTML::DocumentFragment.parse(Redcarpet::Markdown.new(::TranslatedHtml).render(markdown.to_s))
      @blank = fragment.text.blank?
      @definitions = {}
      @html = build_html(fragment)
    end

    def blank?
      @blank
    end

    # Markup comes from TranslatedHtml with escape_html on; only dl/dt/dd and ids are added here.
    def html
      @html.html_safe
    end

    def definition(term)
      @definitions[self.class.anchor(term)]
    end

    private def build_html(fragment)
      intro = []
      entries = []
      fragment.children.each do |node|
        if node.element? && node.matches?(HEADINGS)
          entries << { term: node, body: [] }
        elsif entries.any?
          entries.last[:body] << node
        else
          intro << node
        end
      end
      return intro.map(&:to_html).join if entries.empty?

      items = entries.map do |entry|
        id = self.class.anchor(entry[:term].text)
        id_attr = ''
        unless @definitions.key?(id)
          id_attr = " id=\"#{id}\""
          @definitions[id] = entry[:body].select(&:element?).map { |n| n.text.squish }.join(' ').presence
        end
        "<dt#{id_attr}>#{entry[:term].inner_html}</dt><dd>#{entry[:body].map(&:to_html).join.strip}</dd>"
      end
      "#{intro.map(&:to_html).join}<dl>#{items.join}</dl>"
    end
  end
end
