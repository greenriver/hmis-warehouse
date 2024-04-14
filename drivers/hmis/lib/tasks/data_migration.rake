namespace :data_migration do
  # rails driver:hmis:data_migration:update_project_pk
  desc 'One time task to set Enrollment.project_pk'
  task :update_project_pk, [] => [:environment] do
    data_source = GrdaWarehouse::DataSource.hmis.first
    return unless data_source

    connection = Hmis::Hud::Enrollment.connection
    puts 'updating enrollments from hmis_wip'
    connection.execute(<<~SQL)
      UPDATE "Enrollment"
        SET project_pk = "hmis_wips".project_id
      FROM "hmis_wips"
        WHERE "hmis_wips"."source_id" = "Enrollment"."id"
        AND "hmis_wips"."source_type" = 'Hmis::Hud::Enrollment'
        AND "Enrollment"."data_source_id" = #{data_source.id}
        AND "Enrollment"."ProjectID" IS NULL
    SQL

    puts 'updating enrollments from project'
    connection.execute(<<~SQL)
      UPDATE "Enrollment"
        SET project_pk = "Project".id
      FROM "Project"
        WHERE "Project"."data_source_id" = "Enrollment"."data_source_id"
        AND "Project"."ProjectID" = "Enrollment"."ProjectID"
        AND "Enrollment"."data_source_id" = #{data_source.id}
    SQL
    connection.execute('VACUUM ANALYZE "Enrollment"')
  end
end
