###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# aws-vault exec openpath -- docker compose run shell bundle exec rails runner 'EtlViewMaintainer::Generator.save_to_s3'
module EtlViewMaintainer
  class Generator
    include ArelHelper

    def self.save_to_s3(range: (1.weeks.ago.to_date .. Date.current), bucket: ENV.fetch('S3_BUCKET_DATA_TEAM'))
      key = "warehouse.denormalized.#{Rails.env}.#{range.first.to_s(:db)}.to.#{range.last.to_s(:db)}.csv"
      s3_object = Aws::S3::Object.new(bucket, key)

      options = {
        content_disposition: "attachment; filename=\"#{key}\"",
        content_type: 'text/csv',
      }

      # Make it even more obvious the file is just for testing
      sql_to_run = Rails.env.development? ? 'select * from schema_migrations' : view_sql(range)

      s3_object.upload_stream(options) do |write_stream|
        to_csv(sql_to_run) do |row|
          write_stream << row
        end
      end
    end

    # Fetch the request of a query as a CSV row by row
    def self.to_csv(query, &block)
      raw = GrdaWarehouseBase.connection.raw_connection

      statement = <<~SQL
        COPY (#{query}) TO STDIN
        WITH CSV HEADER DELIMITER ',' QUOTE '"'
      SQL

      raw.copy_data statement do |_|
        row = raw.get_copy_data
        while row.present?
          block.call(row)
          row = raw.get_copy_data
        end
      end
    end

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
