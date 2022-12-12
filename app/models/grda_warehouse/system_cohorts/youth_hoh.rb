###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group).
          joins(:projects).
          pluck(p_t[:id])
        enrollments = GrdaWarehouse::Hud::Enrollment.open_on_date(@processing_date).joins(:project).
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
  end
end
