module GrdaWarehouse::HMIS
  class EntryAssessment <  Assessment
    delegate :entry_date, to: :source_object, allow_nil: true
  end
end