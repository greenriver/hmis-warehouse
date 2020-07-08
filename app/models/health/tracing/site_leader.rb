###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class SiteLeader < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case

    def self.label_for(column_name)
      @label_for ||= {
        investigator: 'Investigator name',
        site_name: 'Site name',
        site_leader_name: 'Site leader name',
        contacted_on: 'Notification date',
      }
      @label_for[column_name]
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end

