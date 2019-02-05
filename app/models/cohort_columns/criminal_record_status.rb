module CohortColumns
  class CriminalRecordStatus < Select
    attribute :column, String, lazy: true, default: :criminal_record_status
    attribute :translation_key, String, lazy: true, default: 'Criminal Record Status'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
