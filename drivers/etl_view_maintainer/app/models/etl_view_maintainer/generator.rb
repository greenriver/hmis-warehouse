###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EtlViewMaintainer
  class Generator
    include ArelHelper

    def self.view_sql(range = (1.weeks.ago.to_date .. Date.current))
      scope(range).select(*columns).to_sql
    end

    def self.scope(range = (1.weeks.ago.to_date .. Date.current))
      sql_structure.where(query_for_range(range))
    end

    def self.query_for_range(range = (1.weeks.ago.to_date .. Date.current))
      d_1_start = range.first
      d_1_end = range.last
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end))
    end

    def self.sql_structure
      ::GrdaWarehouse::Hud::Client.destination.
        left_outer_joins(
          source_enrollments: [
            :exit,
            :disabilities,
            :health_and_dvs,
            :employment_educations,
            :enrollment_cocs,
            :income_benefits,
            :youth_education_statuses,
            :events,
            :current_living_situations,
            :services,
            assessments: :assessment_results,
            project: [
              :project_cocs,
              :inventories,
              :funders,
              :organization,
              :affiliations,
              :residential_affiliations,
            ],
          ],
        )
    end

    def self.columns
      included_classes.flat_map(&:columns_for_etl_view)
    end

    # just call this from the extension unless you need to do some pre-calculation
    def self.basic_columns_for_etl_view(column_names, klass)
      column_names.map { |c| klass.arel_table[c].as("#{klass.table_name.underscore}__#{c.underscore}").to_sql }
    end

    def self.included_classes
      [
        ::GrdaWarehouse::Hud::Client,
        ::GrdaWarehouse::Hud::Enrollment,
        ::GrdaWarehouse::Hud::Project,
        ::GrdaWarehouse::Hud::Organization,
        ::GrdaWarehouse::Hud::Funder,
        ::GrdaWarehouse::Hud::Inventory,
        ::GrdaWarehouse::Hud::ProjectCoc,
        ::GrdaWarehouse::Hud::Affiliation,
        ::GrdaWarehouse::Hud::Exit,
        ::GrdaWarehouse::Hud::EnrollmentCoc,
        ::GrdaWarehouse::Hud::Disability,
        ::GrdaWarehouse::Hud::Event,
        ::GrdaWarehouse::Hud::EmploymentEducation,
        ::GrdaWarehouse::Hud::HealthAndDv,
        ::GrdaWarehouse::Hud::IncomeBenefit,
        ::GrdaWarehouse::Hud::CurrentLivingSituation,
        ::GrdaWarehouse::Hud::Assessment,
        ::GrdaWarehouse::Hud::Service,
        ::GrdaWarehouse::Hud::AssessmentResult,
      ]
    end
  end
end
