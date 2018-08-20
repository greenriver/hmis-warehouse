module GrdaWarehouse
  class CohortColumnOption < GrdaWarehouseBase
    validates_presence_of :cohort_column, :weight
    
    def cohort_columns 
      [
        'Housing Track Suggested', 
        'Housing Track Enrolled',
        'Agency',
        'Chapter 115',
        'Criminal Record Status',
        'Destination',
        'Document Ready',
        'Housing Opportunity',
        'Housing Search Agency',
        'Housing Track Enrolled',
        'Housing Track Suggested',
        'Legal Barriers',
        'Location Type',
        'Location',
        'New Lease Referral',
        'Not a Vet', 
        'Primary Housing Track Suggested',
        'Sensory Impaired',
        'St. Francis House',
        'Status',
        'Subpopulation',
        'VA Eligible',
      ]
    end
    
  end
end
