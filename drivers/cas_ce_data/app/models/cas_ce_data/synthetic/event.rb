###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      source.event
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
      # Replaced the following with a lateral join for performance, leaving temporarily for easy reversal
      # new_events = CasCeData::GrdaWarehouse::CasReferralEvent.where.not(id: self.select(:source_id))
      existing = where('"cas_referral_events"."id" = source_id').select(:source_id).limit(1)
      new_events = CasCeData::GrdaWarehouse::CasReferralEvent.
        joins("LEFT JOIN LATERAL (#{existing.to_sql}) findings ON true").
        where('findings.source_id is NULL')
      new_events.find_each do |event|
        next unless event.client.present?
        next unless event.referral_date.present?

        enrollment = find_enrollment(event)
        create(enrollment: enrollment, client: event.client, source: event) if enrollment.present?
      end
    end

    def self.find_enrollment(event)
      date = event.referral_date
      range = date - 90.days .. date
      scope = event.client.source_enrollments.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.coc_funded.ce_participating(range)).
        open_during_range(range).
        order(EntryDate: :desc)
      # If we have an enrollment with an assessment, use it
      # NOTE: this would be more efficient as left_outer_joins with nulls last
      scope = scope.joins(:assessments) if scope.joins(:assessments).exists?
      scope = scope.where(p_t[:id].in(event.projects.pluck(:id))) if event.projects.exists?

      scope.first
    end
  end
end
