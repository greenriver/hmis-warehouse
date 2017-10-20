module ServiceHistory
  class RebuildEnrollmentsJob < ActiveJob::Base
    include ArelHelper

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
        client = GrdaWarehouse::Hud::Client.find(client_id)
        enrollments = GrdaWarehouse::Hud::Client.where(id: client_id).
          joins(:source_enrollments).
          pluck(e_t[:id].as('enrollment_id').to_sql)
        Rails.logger.debug "===RebuildEnrollmentsJob=== Processing #{enrollments.size} enrollments for #{client_id}"
        rebuild_types = []
        enrollments.each do |enrollment_id|
          # Rails.logger.debug "rebuilding enrollment #{enrollment_id}"
          enrollment = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment_id)
          rebuild_types << enrollment.rebuild_service_history!
        end
        if rebuild_types.include?(:update)
          counts[:updated] += 1
          to_sanity_check << client_id
        elsif rebuild_types.include?(:patch)
          counts[:patched] += 1
          to_sanity_check << client_id
        end
        GrdaWarehouse::Tasks::ServiceHistory::Base.new.mark_processed(client_id)
      end
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(to_sanity_check.size, to_sanity_check).run!
      log.update(counts)
    end

    def enqueue(job, queue: :service_history)
    end

    def max_attempts
      2
    end

  end
end