###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class YouthHoh < CurrentlyHomeless
    include ArelHelper
    def cohort_name
      'Youth (under 25) and Head of Household'
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_and_hoh_client_ids)
    end

    private def project_group
      @project_group ||= ::GrdaWarehouse::Config.get(:youth_hoh_cohort_project_group_id)
    end

    # This is a special case, we limit to youth enrolled in a project
    # that is included in the selected project group (if a project groups is present)
    private def households(hoh_only: false)
      return super(hoh_only: hoh_only) unless project_group.present?

      @households ||= {}.tap do |hh|
        enrollments = GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date).
          joins(:project).
          merge(GrdaWarehouse::Hud::Project.where(id: project_ids))
        enrollments = enrollments.heads_of_households if hoh_only
        enrollments.preload(:destination_client).find_in_batches(batch_size: 250) do |batch|
          batch.each do |enrollment|
            next unless enrollment.destination_client

            hh[get_hh_id(enrollment)] ||= []
            hh[get_hh_id(enrollment)] << {
              client_id: enrollment.destination_client.id,
              age: enrollment.destination_client.age,
              relationship_to_hoh: enrollment.RelationshipToHoH,
            }.with_indifferent_access
          end
          GC.start
        end
      end
    end

    private def project_ids
      @project_ids ||= GrdaWarehouse::ProjectGroup.where(id: project_group).
        joins(:projects).
        pluck(p_t[:id])
    end

    private def candidate_enrollments
      return super unless project_group.present?

      @candidate_enrollments ||= enrollment_source.
        # homeless. # Not limiting to homeless since we're limiting by project group
        ongoing(on_date: @processing_date). # who's enrollment is open today
        with_service_between(start_date: inactive_date, end_date: @processing_date). # who received service in the past 90 days
        where.not( # who didn't receive a non-homeless (housed) service on the processing date
          client_id: service_history_source.
            where(date: @processing_date, homeless: false).
            select(:client_id),
        ).
        where.not(client_id: moved_in_ph). # who aren't currently enrolled and moved-in to PH
        where.not(client_id: cohort_clients.select(:client_id)). # who aren't on the cohort currently
        group(:client_id).minimum(:first_date_in_program)
    end

    private def active_ongoing_homeless_enrollments
      return super unless project_group.present?

      enrollment_source.
        # homeless. # Not limiting to homeless since we're limiting by project group
        ongoing(on_date: @processing_date).
        with_service_between(start_date: inactive_date, end_date: @processing_date).
        # Require an ongoing enrollment in the project group
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(id: project_ids)).
        where(client_id: cohort_clients.select(:client_id)).
        distinct.
        pluck(:client_id)
    end

    private def active_client_ids
      return super unless project_group.present?

      enrollment_source.
        # homeless. # Not limiting to homeless since we're limiting by project group
        ongoing(on_date: @processing_date).
        where(client_id: cohort_clients.select(:client_id)).
        joins(:service_history_services).
        where(shs_t[:date].between(inactive_date..@processing_date)).
        distinct.
        pluck(:client_id)
    end

    private def with_homeless_enrollment
      return super unless project_group.present?

      enrollment_source.
        # homeless. # Not limiting to homeless since we're limiting by project group
        ongoing(on_date: @processing_date)
    end
  end
end
