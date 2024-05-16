# Future migration needs:
#
#   - drop of old parent table
#   - drop of triggers
#
#   This all might look scary, but we never drop any of the sub-tables

class ServiceHistoryServicesPartitioning < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      test_query = %(EXPLAIN SELECT "date" FROM "service_history_services" WHERE  "date" between '2022-06-01' AND '2022-06-30')
      original_plan = execute(test_query).to_a.map(&:values).join("\n")

      Rails.logger.info 'Preparing a temporary table we can copy the structure of'
      execute %(CREATE TABLE service_history_services_tmp (LIKE service_history_services INCLUDING ALL))
      execute %(ALTER TABLE service_history_services_tmp DROP CONSTRAINT service_history_services_tmp_pkey)
      execute %(ALTER TABLE service_history_services_tmp ADD PRIMARY KEY (id, "date"))

      Rails.logger.info 'Creating partitioned table'
      execute %(CREATE TABLE service_history_services_partitioned (LIKE service_history_services_tmp INCLUDING ALL) PARTITION BY RANGE ("date"))
      execute %(DROP TABLE service_history_services_tmp)

      Rails.logger.info 'Detatching subtables from parent'
      GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, table|
        execute %(ALTER TABLE #{table} NO INHERIT service_history_services)
        execute %(ALTER TABLE #{table} DROP constraint "service_history_services_#{year}_date_check")
      end

      execute %(ALTER TABLE service_history_services_remainder NO INHERIT service_history_services)
      execute %(ALTER TABLE service_history_services_remainder DROP constraint "service_history_services_remainder_date_check")

      Rails.logger.info 'Reatatching subtables to new parent'
      GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, table|
        # Inclusive at lower end, and exclusive at upper end.
        dates = [Date.new(year, 1, 1).to_fs(:db), Date.new(year + 1, 1, 1).to_fs(:db)]
        execute %(ALTER TABLE service_history_services_partitioned ATTACH PARTITION #{table} FOR VALUES FROM ('#{dates[0]}') TO ('#{dates[1]}'))
      end

      execute %(ALTER TABLE service_history_services_partitioned ATTACH PARTITION service_history_services_remainder DEFAULT)

      Rails.logger.info 'Renaming tables to make new partitioned table available to the application'
      execute %(ALTER TABLE service_history_services RENAME TO service_history_services_was_for_inheritance)
      execute %(ALTER TABLE service_history_services_partitioned RENAME TO service_history_services)

      new_plan = execute(test_query).to_a.map(&:values).join("\n")
      puts "\nOriginal Plan:\n#{original_plan}\n\n"
      puts "New Plan (look at cost):\n#{new_plan}"

      service_history_view
    end
  end

  def down
    safety_assured do
      Rails.logger.info 'Detatching subtables'
      GrdaWarehouse::ServiceHistoryService.sub_tables.each do |_year, table|
        execute %(ALTER TABLE service_history_services DETACH PARTITION #{table})
      end

      execute %(ALTER TABLE service_history_services DETACH PARTITION service_history_services_remainder)

      Rails.logger.info 'Retatching subtables to inherited'
      GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, table|
        execute %(ALTER TABLE #{table} ADD constraint "service_history_services_#{year}_date_check" CHECK (date >= '#{year}-01-01'::date AND date <= '#{year}-12-31'::date) )
        execute %(ALTER TABLE #{table} INHERIT service_history_services_was_for_inheritance)
      end

      execute %(ALTER TABLE service_history_services_remainder ADD constraint "service_history_services_remainder_date_check" CHECK (date < '2000-01-01'::date OR date > '2050-12-31'::date) )
      execute %(ALTER TABLE service_history_services_remainder INHERIT service_history_services_was_for_inheritance)

      Rails.logger.info 'Renaming tables to make old partitioned table available to the application'
      execute %(ALTER TABLE service_history_services RENAME TO service_history_services_delete_me)
      execute %(ALTER TABLE service_history_services_was_for_inheritance RENAME TO service_history_services)

      results = execute(%(select count(*) AS cnt FROM service_history_services_delete_me))

      # This shouldn't be possible. Just being extra careful.
      raise "For some reason service_history_services_delete_me wasn't empty!!!!" unless results.to_a.first['cnt'] == 0

      execute(%(DROP TABLE service_history_services_delete_me))

      service_history_view
    end
  end

  def service_history_view
    execute('DROP VIEW public.service_history')

    execute(<<~SQL)
      CREATE VIEW public.service_history AS
       SELECT service_history_services.id,
          service_history_services.client_id,
          service_history_enrollments.data_source_id,
          service_history_services.date,
          service_history_enrollments.first_date_in_program,
          service_history_enrollments.last_date_in_program,
          service_history_enrollments.enrollment_group_id,
          service_history_enrollments.project_id,
          service_history_services.age,
          service_history_enrollments.destination,
          service_history_enrollments.head_of_household_id,
          service_history_enrollments.household_id,
          service_history_enrollments.project_name,
          service_history_services.project_type,
          service_history_enrollments.project_tracking_method,
          service_history_enrollments.organization_id,
          service_history_services.record_type,
          service_history_enrollments.housing_status_at_entry,
          service_history_enrollments.housing_status_at_exit,
          service_history_services.service_type,
          service_history_enrollments.computed_project_type,
          service_history_enrollments.presented_as_individual,
          service_history_enrollments.other_clients_over_25,
          service_history_enrollments.other_clients_under_18,
          service_history_enrollments.other_clients_between_18_and_25,
          service_history_enrollments.unaccompanied_youth,
          service_history_enrollments.parenting_youth,
          service_history_enrollments.parenting_juvenile,
          service_history_enrollments.children_only,
          service_history_enrollments.individual_adult,
          service_history_enrollments.individual_elder,
          service_history_enrollments.head_of_household
         FROM (public.service_history_services
           JOIN public.service_history_enrollments ON ((service_history_services.service_history_enrollment_id = service_history_enrollments.id)))
      UNION
       SELECT service_history_enrollments.id,
          service_history_enrollments.client_id,
          service_history_enrollments.data_source_id,
          service_history_enrollments.date,
          service_history_enrollments.first_date_in_program,
          service_history_enrollments.last_date_in_program,
          service_history_enrollments.enrollment_group_id,
          service_history_enrollments.project_id,
          service_history_enrollments.age,
          service_history_enrollments.destination,
          service_history_enrollments.head_of_household_id,
          service_history_enrollments.household_id,
          service_history_enrollments.project_name,
          service_history_enrollments.project_type,
          service_history_enrollments.project_tracking_method,
          service_history_enrollments.organization_id,
          service_history_enrollments.record_type,
          service_history_enrollments.housing_status_at_entry,
          service_history_enrollments.housing_status_at_exit,
          service_history_enrollments.service_type,
          service_history_enrollments.computed_project_type,
          service_history_enrollments.presented_as_individual,
          service_history_enrollments.other_clients_over_25,
          service_history_enrollments.other_clients_under_18,
          service_history_enrollments.other_clients_between_18_and_25,
          service_history_enrollments.unaccompanied_youth,
          service_history_enrollments.parenting_youth,
          service_history_enrollments.parenting_juvenile,
          service_history_enrollments.children_only,
          service_history_enrollments.individual_adult,
          service_history_enrollments.individual_elder,
          service_history_enrollments.head_of_household
         FROM public.service_history_enrollments;
    SQL
  end
end
