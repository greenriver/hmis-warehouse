namespace :data_migration do
  # rails driver:hmis:data_migration:update_actual_project
  desc 'One time task to set Enrollment.actual_project_id'
  task :update_actual_project, [] => [:environment] do
    data_source = GrdaWarehouse::DataSource.hmis.first
    return unless data_source

    connection = Hmis::Hud::Enrollment.connection
    puts 'updating enrollments from hmis_wip'
    connection.execute(<<~SQL)
      UPDATE "Enrollment"
        SET actual_project_id = "hmis_wips".project_id
      FROM "hmis_wips"
        WHERE "hmis_wips"."source_id" = "Enrollment"."id"
        AND "hmis_wips"."source_type" = 'Hmis::Hud::Enrollment'
        AND "Enrollment"."data_source_id" = #{data_source.id}
    SQL

    puts 'updating enrollments from project'
    connection.execute(<<~SQL)
      UPDATE "Enrollment"
        SET actual_project_id = "Project".id
      FROM "Project"
        WHERE "Project"."data_source_id" = "Enrollment"."data_source_id"
        AND "Project"."ProjectID" = "Enrollment"."ProjectID"
        AND "Enrollment"."data_source_id" = #{data_source.id}
    SQL
    connection.execute('VACUUM ANALYZE "Enrollment"')
  end
end
