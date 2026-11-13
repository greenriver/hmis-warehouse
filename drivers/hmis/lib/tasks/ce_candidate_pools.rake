###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis:ce_candidate_pool_builder
desc 'Rebuild the CE match candidate pools'
task ce_candidate_pool_builder: [:environment, 'log:info_to_stdout'] do
  next unless HmisEnforcement.hmis_enabled? && GrdaWarehouse::DataSource.hmis.exists? && Hmis::Ce.configuration.enabled?

  # Catch-all CE reprocessing. Ensures we don't miss changes that could impact eligibility
  GrdaWarehouse::Tasks::TaskInstrumentation.call(
    'Hmis::Ce::Match::CandidatePoolBuilder',
    alert_threshold: 36.hours,
  ) do |run|
    # lock_for_maintenance!'s transaction-scoped lock is released as soon as its own transaction
    # ends, so it needs an explicit transaction here to stay held for the block's duration
    Hmis::Ce::Match::CandidatePool.transaction do
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance!(timeout_seconds: 5.minutes) do
        Hmis::Ce::Match::CandidatePoolBuilder.call(force_reprocessing: true)
      end
    end
    run.complete!
  end
end
