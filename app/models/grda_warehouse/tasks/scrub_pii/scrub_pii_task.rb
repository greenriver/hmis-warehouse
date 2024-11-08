###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  class ScrubPiiTask
    attr_accessor :strategy

    def self.perform(...)
      new.perform(...)
    end

    STRATEGIES = {
      null: NullStrategy,
      fake: FakeStrategy,
      identifier: IdentifierStrategy,
    }.freeze

    def perform(client_ids: nil, data_source_ids: nil, strategy: :null, prng_seed: nil)
      with_lock do
        Faker::Config.random = Random.new(prng_seed) if prng_seed
        raise ArgumentError, "unknown strategy #{strategy}" unless STRATEGIES.key?(strategy)
        @strategy = STRATEGIES[strategy].new


        GrdaWarehouse::Hud::Client.unscoped do # turn off soft-delete
          client_scope(client_ids: client_ids, data_source_ids: data_source_ids).find_in_batches do |clients|
            GrdaWarehouse::Hud::Client.transaction do
              process_client_batch(clients)
            end
          end
        end
      end
    end

    protected

    def with_lock(&block)
      GrdaWarehouseBase.with_advisory_lock('identify_external_clients', timeout_seconds: 0, &block)
    end

    def process_client_batch(clients)
      scrub_clients(clients)
      scrub_custom_data_elements(GrdaWarehouse::Hud::Client, clients.map(&:id))
      delete_versions(GrdaWarehouse::Hud::Client, clients.map(&:id))

      data_source_ids = clients.map(&:data_source_id).uniq
      data_source_ids.each do |data_source_id|
        delete_hmis_client_records(clients, data_source_id)

        GrdaWarehouse::Hud::Enrollment.unscoped do
          enrollments = GrdaWarehouse::Hud::Enrollment.where(data_source: data_source_id, PersonalID: clients.map(&:PersonalID))
          scrub_enrollments(enrollments)
          scrub_custom_data_elements(GrdaWarehouse::Hud::Enrollment, enrollments.map(&:id))
          delete_versions(GrdaWarehouse::Hud::Enrollment, enrollments.map(&:id))
        end
      end
    end

    def scrub_custom_data_elements(klass, ids)
      Hmis::Hud::CustomDataElement.unscoped do
        scope = Hmis::Hud::CustomDataElement.
          where(owner_type: klass.sti_name, owner_id: ids).
          joins(:data_element_definition)
        arel = Hmis::Hud::CustomDataElementDefinition.arel_table
        ssns = Hmis::Hud::CustomDataElementDefinition.where(arel[:label].matches("%SSN%"))
        dobs = Hmis::Hud::CustomDataElementDefinition.where(arel[:label].matches("%DOB%"))

        # FIXME - should probably call strategy rather than delete
        scope.merge(ssns).delete_all
        scope.merge(dobs).delete_all
      end
    end

    def scrub_clients(clients)
      values = clients.map do |client|
        strategy.client_attrs(client)
      end
      import!(GrdaWarehouse::Hud::Client, values)
    end

    def scrub_enrollments(enrollments)
      return if enrollments.empty?

      values = enrollments.map do |enrollment|
        strategy.enrollment_attrs(enrollment)
      end
      import!(GrdaWarehouse::Hud::Enrollment, values)
    end

    def import!(klass, values)
      return if values.blank?
      result = klass.import(values, on_duplicate_key_update: { conflict_target: [:id], columns: values.first.keys }, validate: false)
      raise if result.failed_instances.any?
    end

    def delete_hmis_client_records(clients, data_source_id)
      [
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
      ].each do |model|
        model.unscoped do
          scope = model.where(data_source_id: data_source_id, PersonalID: clients.map(&:PersonalID))
          delete_versions(model, scope.pluck(:id))
          scope.delete_all
        end
      end
    end

    def delete_versions(item_type, item_ids)
      GrdaWarehouse::Version.where(item_type: item_type.sti_name, item_id: item_ids).delete_all
    end

    def client_scope(client_ids: nil, data_source_ids: nil)
      scope = GrdaWarehouse::Hud::Client
      scope = scope.where(id: client_ids) if client_ids
      scope = scope.where(data_source_id: data_source_ids) if data_source_ids
      scope
    end
  end
end
