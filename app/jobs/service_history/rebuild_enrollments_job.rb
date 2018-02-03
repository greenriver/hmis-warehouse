module ServiceHistory
  class RebuildEnrollmentsJob < ActiveJob::Base
    include ArelHelper
    queue_as :low_priority

    def initialize client_ids:, log_id:
      @client_ids = client_ids
      @log_id = log_id
    end

    def perform 
      Rails.logger.debug "===RebuildEnrollmentsJob=== Starting to rebuild enrollments for #{@client_ids.size} clients"
      log = GrdaWarehouse::GenerateServiceHistoryBatchLog.create(
        to_process: @client_ids.count, 
        generate_service_history_log_id: @log_id,
        delayed_job_id: self.job_id
      )
      counts = {
        updated: 0,
        patched: 0,
      }
      to_sanity_check = []
      @client_ids.each do |client_id|
        # Rails.logger.debug "rebuilding enrollments for #{client_id}"
        client = GrdaWarehouse::Hud::Client.destination.find(client_id)
        next if client.blank?
        # If this client has been invalidated, remove all service history and rebuild
        if client.service_history_invalidated?
          client.force_full_service_history_rebuild
        end
        # You must join in the project here or it will try to rebuild enrollments
        # with no project
        enrollments = GrdaWarehouse::Hud::Client.where(id: client_id).
          joins(source_enrollments: :project).
          pluck(e_t[:id].as('enrollment_id').to_sql)
        Rails.logger.info "===RebuildEnrollmentsJob=== Processing #{enrollments.size} enrollments for #{client_id}"
        rebuild_types = []
        enrollments.each do |enrollment_id|
          # Rails.logger.debug "rebuilding enrollment #{enrollment_id}"
          enrollment = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment_id)
          rebuild_type = enrollment.rebuild_service_history!
          if rebuild_type == :update
            Rails.logger.info "===RebuildEnrollmentsJob=== Rebuilt #{enrollment_id} for #{client_id}"
          end
          rebuild_types << rebuild_type
        end
        if rebuild_types.include?(:update)
          counts[:updated] += 1
          to_sanity_check << client_id
        elsif rebuild_types.include?(:patch)
          counts[:patched] += 1
          to_sanity_check << client_id
        end
        processor = GrdaWarehouse::Tasks::ServiceHistory::Base.new
        processor.ensure_there_are_no_extra_enrollments_in_service_history(client_id)
        processor.mark_processed(client_id)
      end
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(to_sanity_check.size, to_sanity_check).run!
      log.update(counts)
    end

    def enqueue(job, queue: :low_priority)
    end

    def max_attempts
      2
    end

  end
end