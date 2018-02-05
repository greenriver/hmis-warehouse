module Filters
  class HmisExport < ::ModelForm
    attribute :start_date, Date, default: 1.years.ago.to_date
    attribute :end_date, Date, default: Date.today
    attribute :hash_status, Integer, default: 1
    attribute :include_deleted,  Boolean, default: false
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    
    validates_presence_of :start_date, :end_date

    validate do
      if end_date.present? && start_date.present? 
        if end_date < start_date
          errors.add :end_date, 'must follow start date'
        end
      end
    end
  end
end