###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

    belongs_to :case, optional: true

    def self.label_for(column_name)
      @label_for ||= {
        investigator: 'Investigator name',
        site_name: 'Site name',
        site_leader_name: 'Site leader name',
        contacted_on: 'Notification date',
      }
      @label_for[column_name]
    end

    def self.site_manager_columns
      {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        site: {
          section_header: 'SITE LEADERS NOTIFIED (e.g., shelter or clinic managers)',
          column_header: 'Site',
        },
        site_leader: {
          section_header: '',
          column_header: 'Site Leader Name',
        },
        notification_date: {
          section_header: '',
          column_header: 'Notified Date',
        },
      }.freeze
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end
