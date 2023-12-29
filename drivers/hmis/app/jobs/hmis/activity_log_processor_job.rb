###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = Hmis ActivityLogProcessorJob
#
# Link the access logs for graphql object/fields to database ids for root entity types (client, enrollment, project).
# This linking is done async to avoid overhead of doing it inside a request
#
module Hmis
  class ActivityLogProcessorJob < ::BaseJob
    def perform(force: false)
      Hmis::ActivityLog.with_advisory_lock(
        'AccessLogProcessorLock',
        timeout_seconds: 0, # don't wait
      ) do
        scope = Hmis::ActivityLog.all
        scope = scope.unprocessed unless force
        process_records(scope)
      end
    end

    protected

    RESOLVE_ENROLLMENT_IDS = ->(enrollment_ids) {
      e_t = Hmis::Hud::Enrollment.arel_table
      c_t = Hmis::Hud::Client.arel_table
      client_ids_map = Hmis::Hud::Enrollment.with_deleted.
        where(id: enrollment_ids).
        joins(
          e_t.create_join(
            c_t,
            e_t.create_on(
              # joins to clients; intentionally includes deleted records
              [e_t[:PersonalID].eq(c_t[:PersonalID]), e_t[:data_source_id].eq(c_t[:data_source_id])].inject(&:and),
            ),
          ),
        ).
        pluck(e_t[:id], c_t[:id]).to_h

      enrollment_ids.map do |enrollment_id|
        {
          enrollment_ids: [enrollment_id],
          client_ids: [client_ids_map[enrollment_id&.to_i]],
        }
      end
    }
    # Batch resolve graphql references. Must return 1:1 mapping from ids to entities
    # Note:
    #   * There are many more entities we could resolve against but we only resolve these few to reduce maintenance
    #     burden. It is assumed that to access PII, a query would have to traverse one of the entities below.
    # graphql_name => ->(unique_id_strings) {
    #   [
    #     {client_ids: [], enrollment_ids:[] }
    #   ]
    # }
    RESOLVERS = {
      'Assessment' => ->(assessment_ids) {
        e_t = Hmis::Hud::Enrollment.arel_table
        cas_t = Hmis::Hud::CustomAssessment.arel_table
        enrollment_id_map = Hmis::Hud::CustomAssessment.with_deleted.
          where(id: assessment_ids).
          joins(
            cas_t.create_join(
              e_t,
              cas_t.create_on(
                # joins to enrollments; intentionally includes deleted records
                [
                  e_t[:EnrollmentID].eq(cas_t[:EnrollmentID]),
                  e_t[:PersonalID].eq(cas_t[:PersonalID]), # this seems redundant
                  e_t[:data_source_id].eq(cas_t[:data_source_id]),
                ].inject(&:and),
              ),
            ),
          ).
          pluck(cas_t[:id], e_t[:id]).to_h

        enrollment_ids = assessment_ids.map { |assessment_id| enrollment_id_map[assessment_id&.to_i] }
        RESOLVE_ENROLLMENT_IDS.call(enrollment_ids)
      },
      'Client' => ->(ids) {
        ids.map { |id| { client_ids: [id.to_i] } }
      },
      'Enrollment' => RESOLVE_ENROLLMENT_IDS,
      'EnrollmentSummary' => RESOLVE_ENROLLMENT_IDS,
    }.freeze

    def process_records(scope)
      total_processed = 0
      scope.find_in_batches do |batch|
        # entity references in this batch
        refs_by_type = batch.
          flat_map { |record| record.resolved_fields.keys }. # ["graphql_name/id"]
          map { |key| key.split('/', 2) }. # [[graphql_name, id]]
          each_with_object({}) { |(key, value), obj| (obj[key] ||= []) << value } # {graphql_id => [id]}

        # resolve entity references
        # {"graphql_name/id" => {client_ids: [], enrollment_ids: []}}
        resolved_refs = {}
        RESOLVERS.each do |entity_type, resolver|
          ids = refs_by_type[entity_type]&.uniq
          next unless ids.present?

          resolver.call(ids).each_with_index do |resolved, idx|
            resolved_refs["#{entity_type}/#{ids[idx]}"] = resolved
          end
        end

        # for each log record, build rows for insert from the resolved references
        client_rows = []
        enrollment_rows = []
        batch.each do |log_record|
          log_record.resolved_fields.keys.each do |key|
            resolved = resolved_refs[key]
            next unless resolved

            resolved[:client_ids]&.compact&.each { |id| client_rows << [log_record.id, id] }
            resolved[:enrollment_ids]&.compact&.each { |id| enrollment_rows << [log_record.id, id] }
          end
        end

        # insert the rows and mark log_records as processed
        scope.transaction do
          # populate join tables
          insert_rows(table_name: 'hmis_activity_logs_clients', references: 'client', rows: client_rows.uniq)
          insert_rows(table_name: 'hmis_activity_logs_enrollments', references: 'enrollment', rows: enrollment_rows.uniq)
          scope.where(id: batch.map(&:id)).update_all(processed_at: Time.current)
        end
        total_processed += batch.size
      end
      total_processed
    end

    def insert_rows(table_name:, references:, rows:)
      return if rows.empty?

      values = rows.map do |row|
        "(#{row.map { |c| connection.quote(c) }.join(',')})"
      end
      connection.execute <<~SQL
        INSERT INTO #{table_name} (activity_log_id, #{references}_id) VALUES #{values.join(', ')}
      SQL
    end

    def connection
      Hmis::ActivityLog.connection
    end
  end
end
