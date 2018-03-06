module CohortColumns
  class Notes < Base
    attribute :column, String, lazy: true, default: :notes
    attribute :title, String, lazy: true, default: 'Notes'
    

    def column_editable?
      false
    end

    def default_input_type
      :notes
    end

    def value(cohort_client)
      nil
    end

    def display_for user
      display_read_only
    end

    def display_read_only
      note_count = cohort_client.cohort_client_notes.length
      path = cohort_cohort_client_cohort_client_notes_path(cohort, cohort_client)
      most_recent = cohort_client.cohort_client_notes.ordered.first
      tooltip = ''
      tooltip = truncate(most_recent.note, length: 50, separator: ' ') if most_recent
      link_to note_count, path, class: 'badge', data: {loads_in_pjax_modal: true, toggle: :tooltip, title: tooltip, placement: :right}
    end
  end
end
