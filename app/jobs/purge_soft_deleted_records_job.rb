###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# hard-delete HMIS old soft-deleted records
class PurgeSoftDeletedRecordsJob < BaseJob
  include NotifierConfig

  def perform(retain_at: 1.year.ago, max_deleted: 10_000_000, models: default_models, dry_run: true)
    raise 'all models must be paranoid' unless models.all?(&:paranoid?)

    with_lock do
      @total_deleted = 0
      @max_deleted = max_deleted
      @retain_at = retain_at
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

  # client-related models
  def default_models
    [
      # enrollment-dependent
      GrdaWarehouse::Hud::CurrentLivingSituation,
      GrdaWarehouse::Hud::Disability,
      GrdaWarehouse::Hud::EmploymentEducation,
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

  # tables that have relationships but are not paranoid
  def dependents(model)
    case [model]
    when [GrdaWarehouse::Hud::Client]
      [
        GrdaWarehouse::WarehouseClient.joins(:destination),
        GrdaWarehouse::WarehouseClient.joins(:source),
        GrdaWarehouse::WarehouseClientsProcessed.joins(:client),
      ]
    when [GrdaWarehouse::Hud::Enrollment]
      [
        GrdaWarehouse::EnrollmentExtra.joins(:enrollment),
        GrdaWarehouse::Synthetic::Assessment.joins(:enrollment),
        GrdaWarehouse::Synthetic::Event.joins(:enrollment),
        GrdaWarehouse::Synthetic::YouthEducationStatus.joins(:enrollment),
      ]
    else
      []
    end
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

    scope.in_batches.each do |rel|
      model.transaction do
        dependents(model).each do |dependent_scope|
          dependent_scope = dependent_scope.merge(rel)
          check_max_deleted(dependent_scope.size)
          dependent_scope.delete_all
        end

        check_max_deleted(rel.size)
        rel.delete_all
      end
    end
  end

  def check_max_deleted(size)
    @total_deleted += size
    throw :halt if @total_deleted >= @max_deleted
  end
end
