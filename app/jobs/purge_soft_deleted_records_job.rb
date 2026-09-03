###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Purge soft-deleted client records and their associated data across multiple warehouse models.
#
# This job:
# * Processes records older than a specified retention date
# * Maintains referential integrity by properly handling dependent relationships
# * Enforces a maximum deletion limit as a safety mechanism
class PurgeSoftDeletedRecordsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  # @param retain_at [DateTime] Records deleted before this date will be purged
  # @param max_deleted [Integer] Maximum number of records to delete in one run
  # @param models [Array<Class>] Models to process
  # @param dry_run [Boolean] When true, only counts records that would be deleted (default: true)
  #
  # @return [Integer] Total number of records deleted
  def perform(retain_at: nil, max_deleted: nil, models: warehouse_models, dry_run: true)
    raise 'all models must be paranoid' unless models.all?(&:paranoid?)

    config = SoftDeleteRetentionConfiguration.new
    return 0 unless config.enabled?

    retain_at ||= config.retain_at
    max_deleted ||= config.max_deleted_per_run

    Rails.logger.info "Purging soft-deleted records (#{dry_run ? 'dry run' : 'live run'})"

    with_lock do
      @total_deleted = 0
      @max_deleted = max_deleted
      @retain_at = retain_at
      @dry_run = dry_run
      catch(:halt) do
        models.each do |model|
          model.unscoped do
            if scoped_by_data_source?(model)
              data_sources.order(:id).each { |data_source| process_model(model, data_source: data_source) }
            else
              process_model(model)
            end
          end
        end
      end
    end

    Rails.logger.info "Total records deleted: #{@total_deleted}" unless @dry_run
    @total_deleted
  end

  protected

  def data_sources
    GrdaWarehouse::DataSource
  end

  # client-related warehouse models
  def warehouse_models
    [
      # enrollment-dependent
      GrdaWarehouse::Hud::Assessment,
      GrdaWarehouse::Hud::AssessmentQuestion,
      GrdaWarehouse::Hud::AssessmentResult,
      GrdaWarehouse::Hud::CurrentLivingSituation,
      GrdaWarehouse::Hud::Disability,
      GrdaWarehouse::Hud::EmploymentEducation,
      GrdaWarehouse::Hud::Event,
      GrdaWarehouse::Hud::Exit,
      GrdaWarehouse::Hud::HealthAndDv,
      GrdaWarehouse::Hud::IncomeBenefit,
      GrdaWarehouse::Hud::Service,
      GrdaWarehouse::Hud::YouthEducationStatus,
      Hmis::Hud::CustomAssessment,
      Hmis::Hud::CustomCaseNote,
      Hmis::Hud::CustomClientAddress,
      Hmis::Hud::CustomClientContactPoint,
      Hmis::Hud::CustomClientName,
      Hmis::Hud::CustomDataElement,
      # CE referrals; dependents first
      Hmis::Ce::ReferralNote,
      Hmis::Ce::ReferralParticipant,
      Hmis::Ce::Referral,
      # purge these last
      GrdaWarehouse::Hud::Enrollment,
      GrdaWarehouse::Hud::Client,
    ]
  end

  # CE referrals and their dependents reach their data source only through several paranoid joins, so they're
  # purged across all data sources at once
  def scoped_by_data_source?(model)
    model.column_names.include?('data_source_id')
  end

  # tables with FK relationships need to be deleted. Choosing to leave other dangling references to client
  def client_dependents(client_scope)
    # double check that these are the same table before we start deleting records with that assumption
    raise unless GrdaWarehouse::Hud::Client.table_name == Hmis::Hud::Client.table_name
    raise unless GrdaWarehouse::Hud::Client.connection.current_database == Hmis::Hud::Client.connection.current_database

    rhm_t = HmisExternalApis::AcHmis::ReferralHouseholdMember.arel_table
    [
      GrdaWarehouse::WarehouseClient.joins(:destination).merge(client_scope),
      GrdaWarehouse::WarehouseClient.joins(:source).merge(client_scope),
      GrdaWarehouse::WarehouseClientsProcessed.joins(:client).merge(client_scope),
      HmisExternalApis::AcHmis::ReferralHouseholdMember.where(rhm_t[:client_id].in(client_scope.pluck(:id))),
    ]
  end

  # CE referrals hold FKs to Enrollment on target_enrollment_id and source_enrollment_id. Drop those references
  # before the enrollments go; the referrals themselves are purged on their own retention date.
  # Referrals are paranoid, and a soft-deleted referral still holds the foreign key, so include those here.
  def clear_enrollment_references(enrollment_scope)
    return if @dry_run

    enrollment_ids = enrollment_scope.pluck(:id)
    referrals = Hmis::Ce::Referral.with_deleted
    referrals.where(target_enrollment_id: enrollment_ids).update_all(target_enrollment_id: nil)
    referrals.where(source_enrollment_id: enrollment_ids).update_all(source_enrollment_id: nil)
  end

  def delete_dependents(dependent_scopes)
    dependent_scopes.each do |dependent_scope|
      check_max_deleted(dependent_scope.size)
      dependent_scope.delete_all unless @dry_run
    end
  end

  def with_lock(&block)
    lock_name = self.class.name.demodulize
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end

  def process_model(model, data_source: nil)
    arel = model.arel_table
    paranoia_col = arel[model.paranoia_column.to_sym]
    scope = model.where(paranoia_col.lt(@retain_at))
    scope = scope.where(data_source: data_source) if data_source

    scope.in_batches(of: 5_000).each do |batch|
      model.transaction do
        delete_dependents(client_dependents(batch)) if model == GrdaWarehouse::Hud::Client
        clear_enrollment_references(batch) if model == GrdaWarehouse::Hud::Enrollment

        # even though this throws, it does not rollback the transaction so we could delete more records than the max
        check_max_deleted(batch.size)
        batch.delete_all unless @dry_run
      end
    end
  end

  def check_max_deleted(size)
    @total_deleted += size
    return unless @total_deleted >= @max_deleted

    Rails.logger.info "Reached maximum deletion limit of #{@max_deleted} records, halting job."
    throw :halt
  end
end
