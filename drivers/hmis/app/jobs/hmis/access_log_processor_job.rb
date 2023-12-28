###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = Hmis AccessLogProcessorJob
#
# Link the access logs for graphql object/fields to database ids for root entity types (client, enrollment, project).
# This linking is done async to avoid overhead of doing it inside a request
#
# Notes:
#   * Must be run with paranoia disabled (DANGEROUSLY_DISABLE_SOFT_DELETION=1)
module Hmis
  class AccessLogProcessorJob < BaseJob
    def perform(force: false)
      # this job requires extensive preloading of associations. Running with the `paranoia` gem enabled prevents this
      # job from linking deleted records
      raise 'Refusing to run with soft-delete enabled' if Hmis::Hud::Client.paranoid?

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

    # extracted for re-use
    RESOLVE_ENROLLMENT = ->(enrollment) {
      if enrollment
        {
          enrollment_ids: [enrollment.id],
          client_ids: [enrollment.client.id],
          project_ids: [enrollment.project.id],
        }
      end
    }
    # Batch resolve graphql references. Must return 1:1 mapping from ids to entities
    # graphql_name => ->(unique_id_strings) {
    #   [
    #     {client_ids: [], enrollment_ids:[], project_ids: [] }
    #   ]
    # }
    RESOLVERS = {
      # 'ApplicationUser' => nil,
      'Assessment' => ->(ids) {
        by_id = Hmis::Hud::CustomAssessment.preload(enrollment: [:client, :project]).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]&.enrollment) }
      },
      'Client' => ->(ids) {
        ids.map { |id| { client_ids: [id.to_i] } }
      },
      'ClientAddress' => ->(ids) {
        by_id = Hmis::Hud::CustomClientAddress.preload(:client).where(id: ids).index_by(&:id)
        ids.map do |id|
          client = by_id[id.to_i].client
          { client_ids: [client.id] } if client
        end
      },
      # 'ClientAuditEvent' => nil,
      'ClientName' => ->(ids) {
        by_id = Hmis::Hud::CustomClientName.preload(:client).where(id: ids).index_by(&:id)
        ids.map do |id|
          client = by_id[id.to_i].client
          { client_ids: [client.id] } if client
        end
      },
      'CustomDataElement' => ->(ids) {
        cdes = Hmis::Hud::CustomDataElement.where(id: ids)
        by_owner_type = cdes.group_by(&:owner_type)
        mapped = {}
        [
          [
            Hmis::Hud::Project,
            ->(project) { { project_ids: [project.id] } },
          ],
          [
            Hmis::Hud::Client,
            ->(client) { { client_ids: [client.id] } },
          ],
          [
            Hmis::Hud::Enrollment.preload(:client, :project),
            RESOLVE_ENROLLMENT,
          ],
          [
            Hmis::Hud::Exit.preload(enrollment: [:client, :project]),
            ->(record) { RESOLVE_ENROLLMENT.call(record.enrollment) },
          ],
          [
            Hmis::Hud::CurrentLivingSituation.preload(enrollment: [:client, :project]),
            ->(record) { RESOLVE_ENROLLMENT.call(record.enrollment) },
          ],
        ].each do |scope, resolver|
          owner_id_map = by_owner_type[scope.sti_name]&.to_h { |owner| [owner.id, owner.owner_id] }
          next unless owner_id_map

          owners_by_id = scope.where(id: owner_id_map.values).index_by(&:id)
          owner_id_map.each_pair do |id, owner_id|
            owner = owners_by_id[owner_id]
            mapped[id] = resolver.call(owner) if owner
          end
        end

        ids.map { |id| mapped[id.to_i] }
      },
      # I think we don't need to resolve values since the only way to access them is via CustomDataElement
      # 'CustomDataElementValue' => nil,
      'Enrollment' => ->(ids) {
        by_id = Hmis::Hud::Enrollment.preload(:client, :project).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]) }
      },
      # 'EnrollmentAuditEvent' => nil,
      'Exit' => ->(ids) {
        by_id = Hmis::Hud::Exit.preload(enrollment: [:client, :project]).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]&.enrollment) }
      },
      'ExternalIdentifier' => ->(ids) {
        by_id = HmisExternalApis::ExternalId.where(id: ids).index_by(&:id)
        ids.map do |id|
          external_id = by_id[id]
          case external_id&.source_type
          when Hmis::Hud::Client.sti_name
            { client_ids: [external_id.source_id] }
          end
        end
      },
      'HealthAndDv' => ->(ids) {
        by_id = Hmis::Hud::HealthAndDv.preload(enrollment: [:client, :project]).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]&.enrollment) }
      },
      'Household' => ->(ids) {
        by_id = Hmis::Hud::Household.preload(enrollments: [:client, :project]).where(id: ids).index_by(&:id)
        ids.map do |id|
          household = by_id[id]
          next unless household

          {
            client_ids: household.enrollments.map { |e| e.client.id },
            enrollment_ids: household.enrollments.map(&:id),
            project_ids: household.enrollments.map { |e| e.project.id },
          }
        end
      },
      'HouseholdClient' => ->(ids) {
        # ids are of the form "#{enrollment.id}:#{client.id}"
        ids = ids.map { |id| id.split(':', 2)[0] }
        by_id = Hmis::Hud::Enrollment.preload(:client, :project).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]) }
      },
      'IncomeBenefit' => ->(ids) {
        by_id = Hmis::Hud::IncomeBenefit.preload(enrollment: [:client, :project]).where(id: ids).index_by(&:id)
        ids.map { |id| RESOLVE_ENROLLMENT.call(by_id[id.to_i]&.enrollment) }
      },
      'OccurrencePointForm' => ->(ids) {
        by_id = Hmis::Form::Instance.where(id: ids).index_by(&:id)
        ids.map do |id|
          instance = by_id[id]
          case instance&.entity_type
          when Hmis::Hud::Project.sti_name
            { project_ids: [instance.entity_id] }
          end
        end
      },
      # 'Organization' => nil,
      'Project' => ->(ids) {
        ids.map { |id| { project_ids: [id.to_i] } }
      },
      'Unit' => ->(ids) {
        by_id = Hmis::Unit.where(id: ids).index_by(&:id)
        ids.map do |id|
          unit = by_id[id.to_i]
          { project_ids: [unit.project_id] } if unit
        end
      },
      # 'UnitTypeObject' => nil,
      # 'User' => nil,
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
        # {"graphql_name/id" => {client_ids: [], project_ids: [], enrollment_ids: []}}
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
        project_rows = []
        batch.each do |log_record|
          log_record.resolved_fields.keys.each do |key|
            resolved = resolved_refs[key]
            next unless resolved

            resolved[:client_ids]&.compact&.each { |id| client_rows << [log_record.id, id] }
            resolved[:enrollment_ids]&.compact&.each { |id| enrollment_rows << [log_record.id, id] }
            resolved[:project_ids]&.compact&.each { |id| project_rows << [log_record.id, id] }
          end
        end

        # insert the rows and mark log_records as processed
        scope.transaction do
          # populate join tables
          insert_rows(table_name: 'hmis_activity_logs_clients', references: 'client', rows: client_rows.uniq)
          insert_rows(table_name: 'hmis_activity_logs_enrollments', references: 'enrollment', rows: enrollment_rows.uniq)
          insert_rows(table_name: 'hmis_activity_logs_projects', references: 'project', rows: project_rows.uniq)
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
