###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Notes < Base
    attribute :column, String, lazy: true, default: :notes
    attribute :translation_key, String, lazy: true, default: 'Notes'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

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
      cohort_client.cohort_client_notes.order(updated_at: :desc).map do |note|
        "#{note.note} -- #{note.user&.name} on #{note.updated_at&.to_date}"
      end.join("\r\n\r\n").html_safe
    end

    def display_read_only(_user)
      note_count = cohort_client.cohort_client_notes.length || 0
      unknown_date = DateTime.current - 10.years
      max_updated_at = (cohort_client.cohort_client_notes.map(&:updated_at)&.max || unknown_date).to_s(:db)
      path = cohort_cohort_client_cohort_client_notes_path(cohort, cohort_client)
      # Sort pattern
      html = content_tag(:span, "#{max_updated_at} #{note_count}", class: 'hidden')
      html += link_to pluralize(note_count, 'note'), path, class: 'badge badge-primary py-1 px-2', data: { loads_in_pjax_modal: true, cohort_client_id: cohort_client.id, column: column }
      html
    end

    def text_value(cohort_client)
      self.cohort_client = cohort_client
      comments
    end
  end
end
