# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Purge soft-deleted client records and their associated data across multiple warehouse models.
#
# This job:
# * Processes records older than a specified retention date
# * Maintains referential integrity by properly handling dependent relationships
# * Enforces a maximum deletion limit as a safety mechanism
class PurgeSoftDeletedRecordsJob < BaseJob
  include NotifierConfig

  # @param retain_at [DateTime] Records deleted before this date will be purged
  # @param max_deleted [Integer] Maximum number of records to delete in one run
  # @param models [Array<Class>] Models to process
  # @param dry_run [Boolean] When true, only counts records that would be deleted (default: true)
  #
  # @return [Integer] Total number of records deleted
  def perform(retain_at: 1.year.ago, max_deleted: 10_000_000, models: warehouse_models, dry_run: true)
    raise 'all models must be paranoid' unless models.all?(&:paranoid?)

    with_lock do
      @total_deleted = 0
      @max_deleted = max_deleted
      @retain_at = retain_at
      @dry_run = dry_run
      catch(:halt) do
        data_sources.order(:id).each do |data_source|
          models.each do |model|
            model.unscoped do
              process_model(model, data_source: data_source)
            end
          end
        end
      end
    end
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
      # purge these last
      GrdaWarehouse::Hud::Enrollment,
      GrdaWarehouse::Hud::Client,
    ]
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

  def with_lock(&block)
    lock_name = self.class.name.demodulize
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end

  def process_model(model, data_source:)
    arel = model.arel_table
    paranoia_col = arel[model.paranoia_column.to_sym]
    scope = model.
      where(data_source: data_source).
      where(paranoia_col.lt(@retain_at))

    scope.in_batches(of: 5_000).each do |batch|
      model.transaction do
        if model == GrdaWarehouse::Hud::Client
          client_dependents(batch).each do |dependent_scope|
            check_max_deleted(dependent_scope.size)
            dependent_scope.delete_all unless @dry_run
          end
        end

        # even though this throws, it does not rollback the transaction so we could delete more records than the max
        check_max_deleted(batch.size)
        batch.delete_all unless @dry_run
      end
    end
  end

  def check_max_deleted(size)
    @total_deleted += size
    throw :halt if @total_deleted >= @max_deleted
  end
end
