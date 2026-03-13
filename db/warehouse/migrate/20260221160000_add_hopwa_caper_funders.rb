# frozen_string_literal: true

class AddHopwaCaperFunders < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_reference :hopwa_caper_enrollments, :project

      create_table :hopwa_caper_funders do |t|
        t.references :project, null: false
        t.references :funder, null: false, index: false # for reference
        t.references :report_instance, null: false
        t.string :code
        t.date :start_date
        t.date :end_date
        t.index [:funder_id, :report_instance_id], unique: true
      end

      reversible do |dir|
        dir.up do
          populate_enrollment_project_id
          populate_hopwa_caper_funders
        end
      end
    end
  end

  def populate_enrollment_project_id
    HopwaCaper::Enrollment.reset_column_information

    execute(<<~SQL)
      UPDATE hopwa_caper_enrollments
      SET project_id = "Project".id
      FROM "Enrollment"
      JOIN "Project" ON "Project"."ProjectID" = "Enrollment"."ProjectID" AND "Project".data_source_id = "Enrollment".data_source_id
      WHERE hopwa_caper_enrollments.enrollment_id = "Enrollment".id
    SQL
  end

  def populate_hopwa_caper_funders
    # Ensure we don't try to insert if the table doesn't have metadata yet
    HopwaCaper::Funder.reset_column_information

    execute(<<~SQL)
      INSERT INTO hopwa_caper_funders (
        project_id,
        funder_id,
        report_instance_id,
        code,
        start_date,
        end_date
      )
      SELECT DISTINCT
        hce.project_id,
        f.id,
        hce.report_instance_id,
        f."Funder",
        f."StartDate",
        f."EndDate"
      FROM hopwa_caper_enrollments hce
      JOIN "Enrollment" e ON e.id = hce.enrollment_id
      JOIN "Funder" f ON f."ProjectID" = e."ProjectID" AND f.data_source_id = e.data_source_id
      WHERE hce.project_id IS NOT NULL
      ON CONFLICT (funder_id, report_instance_id) DO NOTHING;
    SQL
  end
end
