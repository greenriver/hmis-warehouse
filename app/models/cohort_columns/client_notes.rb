###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ClientNotes < Base
    attribute :column, String, lazy: true, default: :client_notes
    attribute :translation_key, String, lazy: true, default: 'Client Notes'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def column_editable?
      false
    end

    def default_input_type
      :notes
    end

    def value(_cohort_client) # OK
      nil
    end

    def display_for(user)
      display_read_only(user)
    end

    def renderer
      'html'
    end

    def comments
      cohort_client.client.cohort_notes.sort_by(&:updated_at).reverse.map do |note|
        "#{note.note} -- #{note.user.name} on #{note.updated_at.to_date}"
      end.join("\r\n\r\n").html_safe
    end

    def display_read_only(_user)
      note_count = cohort_client.client.cohort_notes.size || 0
      unknown_date = DateTime.current - 10.years
      updated_at = cohort_client.client.cohort_notes.map(&:updated_at)&.max
      max_updated_at = (updated_at || unknown_date).to_fs(:db)
      path = cohort_cohort_client_client_notes_path(cohort, cohort_client)
      # Sort pattern
      html = content_tag(:div, class: 'd-flex') do
        content_tag(:span, "#{max_updated_at} #{note_count}", class: 'hidden') + link_to(pluralize(note_count, 'note'), path, class: 'badge badge-primary py-1 px-2 mr-auto', data: { loads_in_pjax_modal: true, cohort_client_id: cohort_client.id, column: column }) +
        content_tag(:span, " #{updated_at&.to_date}", style: 'height: 16px;')
      end
      html
    end

    def text_value(cohort_client)
      self.cohort_client = cohort_client
      comments
    end
  end
end
