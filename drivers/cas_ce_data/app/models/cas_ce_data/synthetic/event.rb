###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasCeData::Synthetic
  class Event < ::GrdaWarehouse::Synthetic::Event
    include ArelHelper

    validates_presence_of :source

    def event_date
      source.referral_date
    end

    def event
      case enrollment.project.ProjectType
      when 13 # RRH
        13
      when 3, 10 # PSH
        14
      when 9 # Other PH
        15
      end
    end

    def data_source
      'CAS'
    end

    def referral_result
      source.referral_result
    end

    def result_date
      source.referral_result_date
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - CasCeData::GrdaWarehouse::CasReferralEvent.pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      new_events = CasCeData::GrdaWarehouse::CasReferralEvent.where.not(id: self.select(:source_id))
      new_events.find_each do |event|
        next unless event.client.present?

        enrollment = find_enrollment(event)
        create(enrollment: enrollment, client: event.client, source: event) if enrollment.present?
      end
    end

    def self.find_enrollment(event)
      event.client.source_enrollments.
        joins(:project).
        where(p_t[:id].in(event.projects.pluck(:project_id))).
        open_on_date(event.referral_date).
        first
    end
  end
end
