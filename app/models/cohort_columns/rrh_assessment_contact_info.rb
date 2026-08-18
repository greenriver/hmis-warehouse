###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class RrhAssessmentContactInfo < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_assessment_contact_info
    attribute :translation_key, String, lazy: true, default: 'RRH Income Maximization Contact'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Contact information provided by the client for income maximization services for CAS'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      # FIXME?: contact_info_for_rrh_assessment already checks consent_form_valid?
      cohort_client.client.contact_info_for_rrh_assessment if cohort_client.client.consent_form_valid?
    end

    def text_value(cohort_client)
      strip_tags value(cohort_client)
    end

    # Rendered into the AG Grid cell via innerHTML (see HtmlCellRenderer), so escaping has to be
    # baked into the string itself — JSON serialization drops the html_safe flag.
    def display_read_only(_user)
      raw_text = value(cohort_client)
      return if raw_text.blank?

      # Same paragraph-split ActionView::Helpers::TextHelper#simple_format uses internally
      # (its private split_paragraphs): normalize line endings, then split on blank lines.
      blocks = raw_text.to_s.gsub(/\r\n?/, "\n").split(/\n\n+/).
        map { |block| block.split("\n").map(&:strip).reject(&:blank?).join(', ') }.
        reject(&:blank?)
      content_tag(:span, blocks.join(' | '), title: raw_text.to_s)
    end

    def analytics_value
      text_value(cohort_client)
    end
  end
end
