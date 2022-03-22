###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::HouseholdType
  extend ActiveSupport::Concern

  def household_type_calculations
    @household_type_calculations ||= {}.tap do |calcs|
      calcs['Adult only'] = ->(value) { value == 'adult_only' }
      calcs['Adult and child'] = ->(value) { value == 'adult_and_child' }
      calcs['Child only'] = ->(value) { value == 'child_only' }
      calcs['Unknown'] = ->(value) { value == 'unknown' }
    end
  end

  def standard_household_type_calculation
    she_t_alias = Arel::Table.new(:she_t)
    she_alias_client_join = she_t_alias[:client_id].eq(c_t[:id]).
      and(she_t_alias[:record_type].eq('entry'))
    she_household_where = she_t[:household_id].eq(she_t_alias[:household_id]).
      and(she_t[:project_id].eq(she_t_alias[:project_id])).
      and(she_t[:data_source_id].eq(she_t_alias[:data_source_id])).
      and(she_t_alias[:household_id].not_eq(nil))
    she_no_household_where = she_t[:id].eq(she_t_alias[:id]).and(she_t_alias[:household_id].eq(nil))

    with_households = c_t.project(cl(array_agg(cl(age_calculation, -1)))).
      join(she_t.as('she_t')).on(she_alias_client_join).
      where(she_household_where)

    without_households = c_t.project(cl(array_agg(cl(age_calculation, -1)))).
      join(she_t.as('she_t')).on(she_alias_client_join).
      where(she_no_household_where)

    age_query = cl(Arel.sql("(#{with_households.to_sql})"), Arel.sql("(#{without_households.to_sql})")).to_sql
    household_conditions = [
      ["18 > ALL (#{age_query}) AND 0 < ALL (#{age_query})", 'child_only'],
      ["18 <= ALL (#{age_query})", 'adult_only'],
      ["18 <= ANY (#{age_query}) and int4range(0,18) @> any (#{age_query})", 'adult_and_child'],
    ].freeze

    acase(household_conditions, elsewise: 'unknown', quote: false).as('household_type')
  end
end

# SELECT "service_history_enrollments"."client_id", CASE WHEN (18 > ALL (COALESCE((SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."household_id" = "she_t"."household_id" AND "service_history_enrollments"."project_id" = "she_t"."project_id" AND "service_history_enrollments"."data_source_id" = "she_t"."data_source_id" AND "she_t"."household_id" IS NOT NULL), (SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."id" = "she_t"."id" AND "she_t"."household_id" IS NULL))) AND 0 < ALL (COALESCE((SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."household_id" = "she_t"."household_id" AND "service_history_enrollments"."project_id" = "she_t"."project_id" AND "service_history_enrollments"."data_source_id" = "she_t"."data_source_id" AND "she_t"."household_id" IS NOT NULL), (SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."id" = "she_t"."id" AND "she_t"."household_id" IS NULL)))) THEN ('child_only') WHEN (18 <= ALL (COALESCE((SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."household_id" = "she_t"."household_id" AND "service_history_enrollments"."project_id" = "she_t"."project_id" AND "service_history_enrollments"."data_source_id" = "she_t"."data_source_id" AND "she_t"."household_id" IS NOT NULL), (SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."id" = "she_t"."id" AND "she_t"."household_id" IS NULL)))) THEN ('adult_only') WHEN (18 <= ANY (COALESCE((SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."household_id" = "she_t"."household_id" AND "service_history_enrollments"."project_id" = "she_t"."project_id" AND "service_history_enrollments"."data_source_id" = "she_t"."data_source_id" AND "she_t"."household_id" IS NOT NULL), (SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."id" = "she_t"."id" AND "she_t"."household_id" IS NULL))) and int4range(0,18) @> any (COALESCE((SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."household_id" = "she_t"."household_id" AND "service_history_enrollments"."project_id" = "she_t"."project_id" AND "service_history_enrollments"."data_source_id" = "she_t"."data_source_id" AND "she_t"."household_id" IS NOT NULL), (SELECT COALESCE(ARRAY_AGG(COALESCE(CAST(DATE_PART('YEAR', AGE(GREATEST("service_history_enrollments"."first_date_in_program", '2019-10-01'), "Client"."DOB")) AS integer), -1))) FROM "Client" INNER JOIN "service_history_enrollments" AS she_t ON "she_t"."client_id" = "Client"."id" AND "she_t"."record_type" = 'entry' WHERE "service_history_enrollments"."id" = "she_t"."id" AND "she_t"."household_id" IS NULL)))) THEN ('adult_and_child') ELSE ('unknown') END AS household_type FROM "service_history_enrollments" INNER JOIN "Client" ON "Client"."DateDeleted" IS NULL AND "Client"."id" = "service_history_enrollments"."client_id" WHERE "service_history_enrollments"."record_type" = 'entry' AND ("service_history_enrollments"."last_date_in_program" >= '2019-10-01' OR "service_history_enrollments"."last_date_in_program" IS NULL) AND "service_history_enrollments"."first_date_in_program" <= '2020-01-31'
