module CohortColumns
  class LegalBarriers < Select
    attribute :column, String, lazy: true, default: :legal_barriers
    attribute :title, String, lazy: true, default: _('Legal Barriers')

  end
end
