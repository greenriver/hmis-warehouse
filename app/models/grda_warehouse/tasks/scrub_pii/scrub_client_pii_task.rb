###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'
module GrdaWarehouse::Tasks::ScrubPii
  # Responsible for removing or obfuscating personally identifiable information (PII) from client records.
  #
  # The task supports multiple strategies for handling PII:
  # - :null     - Removes all PII fields by setting them to nil
  # - :fake     - Replaces PII with realistic but fake data (includes 999-prefixed SSNs)
  # - :identifier - Replaces PII with deterministic values based on record IDs
  #
  # Usage:
  #   # Scrub all clients using null strategy
  #   ScrubPiiTask.new.perform(strategy: :null)
  #
  #   # Scrub specific clients using fake data
  #   ScrubPiiTask.new.perform(strategy: :fake, client_ids: [1, 2, 3])
  #
  #   # Scrub clients from specific data sources with deterministic values
  #   ScrubPiiTask.new.perform(strategy: :identifier, data_source_ids: [1, 2])
  #
  #   # Use specific seed for reproducible fake data
  #   ScrubPiiTask.new.perform(strategy: :fake, prng_seed: 12345)
  #
  # The task handles:
  # - Client PII (names, SSN, DOB)
  # - Enrollment PII (addresses)
  # - Custom client records
  # - Custom data elements containing PII
  # - Associated versions of modified records
  #
  # All operations are performed within a transaction and protected by an advisory lock
  # to prevent concurrent modifications.
  #
  # @see BaseStrategy
  # @see FakeStrategy
  # @see IdentifierStrategy
  # @see NullStrategy
  class ScrubClientPiiTask
    attr_accessor :strategy

    def self.perform(...)
      new.perform(...)
    end

    STRATEGIES = {
      null: NullStrategy,
      fake: FakeStrategy,
      identifier: IdentifierStrategy,
    }.freeze

    def perform(client_ids: nil, data_source_ids: nil, strategy: :null, prng_seed: nil, progress: false)
      with_lock do
        Faker::Config.random = Random.new(prng_seed) if prng_seed
        raise ArgumentError, "unknown strategy #{strategy}" unless STRATEGIES.key?(strategy)

        @strategy = STRATEGIES[strategy].new

        scope = client_scope(client_ids: client_ids, data_source_ids: data_source_ids)
        progress_bar = ProgressBar.new(scope.count, :counter, :bar, :percentage, :rate, :eta) if progress
        without_paper_trail do
          process_client_universe(scope, progress_bar)
        end
      end
    end

    protected

    def process_client_universe(scope, progress)
      scope.find_in_batches do |clients|
        # one transaction per batch
        GrdaWarehouse::Hud::Client.transaction do
          process_client_batch(clients)
          progress&.increment!(clients.size)
        end
      end
    end

    def client_scope(client_ids: nil, data_source_ids: nil)
      scope = GrdaWarehouse::Hud::Client.with_deleted
      scope = scope.where(id: client_ids) if client_ids
      scope = scope.where(data_source_id: data_source_ids) if data_source_ids
      scope
    end

    def process_client_batch(clients)
      scrub_clients(clients)

      data_source_ids = clients.map(&:data_source_id).uniq
      data_source_ids.each do |data_source_id|
        delete_hmis_client_records(clients, data_source_id)
        scrub_enrollments(clients, data_source_id)
      end
    end

    def delete_custom_data_elements(model, ids)
      arel = Hmis::Hud::CustomDataElementDefinition.arel_table
      conditions = [
        arel[:label].matches('%SSN%', nil, true), # case sensitive
        arel[:label].matches('%social security number%'),
        arel[:label].matches('%DOB%', nil, true), # case sensitive
        arel[:label].matches('%date of birth%'),
        arel[:label].matches('%first name%'),
        arel[:label].matches('%last name%'),
        arel[:label].matches('%address%'),
        arel[:label].matches('%city%'),
        arel[:label].matches('%email%'),
        arel[:label].matches('%phone%'),
      ].reduce(&:or)

      scope = Hmis::Hud::CustomDataElement.with_deleted.
        where(owner_type: model.sti_name, owner_id: ids).
        joins(:data_element_definition).
        merge(Hmis::Hud::CustomDataElementDefinition.with_deleted.where(conditions))

      delete_versions([Hmis::Hud::CustomDataElement], scope.pluck(:id))
      scope.delete_all
    end

    def scrub_clients(clients)
      values = clients.map do |client|
        strategy.client_attrs(client)
      end
      import!(GrdaWarehouse::Hud::Client, values)

      client_ids = clients.map(&:id)
      delete_custom_data_elements(Hmis::Hud::Client, client_ids)
      delete_versions([GrdaWarehouse::Hud::Client, Hmis::Hud::Client], client_ids)
    end

    def scrub_enrollments(clients, data_source_id)
      enrollments = GrdaWarehouse::Hud::Enrollment.
        with_deleted.
        where(data_source: data_source_id, PersonalID: clients.map(&:PersonalID))
      return if enrollments.to_a.empty?

      values = enrollments.map do |enrollment|
        strategy.enrollment_attrs(enrollment)
      end
      import!(GrdaWarehouse::Hud::Enrollment, values)

      enrollment_ids = enrollments.map(&:id)
      delete_custom_data_elements(Hmis::Hud::Enrollment, enrollment_ids)
      delete_versions([GrdaWarehouse::Hud::Enrollment, Hmis::Hud::Enrollment], enrollment_ids)
    end

    def delete_hmis_client_records(clients, data_source_id)
      personal_ids = clients.map(&:PersonalID)

      # delete from custom tables that may contain sensitive info
      [
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
      ].each do |model|
        scope = model.with_deleted.where(data_source_id: data_source_id, PersonalID: personal_ids)
        delete_versions([model], scope.map(&:id))
        scope.delete_all
      end

      # delete custom data elements from tables that may contain sensitive info
      [
        Hmis::Hud::CustomAssessment,
        # other models?
      ].each do |model|
        scope = model.with_deleted.where(data_source_id: data_source_id, PersonalID: personal_ids)
        delete_custom_data_elements(model, scope.pluck(:id))
      end
    end

    def delete_versions(models, item_ids)
      GrdaWarehouse::Version.where(item_type: models.map(&:sti_name), item_id: item_ids).delete_all
    end

    def import!(klass, values)
      return if values.blank?

      result = klass.import(values, on_duplicate_key_update: { conflict_target: [:id], columns: values.first.keys }, validate: false)
      raise if result.failed_instances.any?
    end

    def without_paper_trail
      pt_was = PaperTrail.enabled?
      PaperTrail.enabled = false
      yield
    ensure
      PaperTrail.enabled = pt_was
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
