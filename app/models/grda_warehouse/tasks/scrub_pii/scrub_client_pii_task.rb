###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  # Scrub personally identifiable information (PII) for selected HMIS client-related records.
  # * Selectively scrub personally identifiable information (PII) for HMIS Clients
  # * Delete client-related custom hmis data
  # * Delete versions
  class ScrubClientPiiTask
    def self.perform(...)
      new.perform(...)
    end

    def perform(client_ids: nil, data_source_ids: nil, custom_scrubber: nil, progress: false)
      with_lock do
        @scrubber = Pii::Scrubber::ScrubModelPii.new(custom_scrubber: custom_scrubber, progress: progress)
        @version_pruner = Pii::Scrubber::VersionHistoryPruner.new

        client_scope = GrdaWarehouse::Hud::Client.with_deleted
        client_scope = client_scope.where(id: client_ids) if client_ids
        client_scope = client_scope.where(data_source_id: data_source_ids) if data_source_ids

        # scrub the client records themselves
        @scrubber.perform(client_scope)

        # iterate through clients in batches and scrub related records
        client_scope.find_in_batches do |clients|
          process_client_batch(clients)
        end
      end
    end

    protected

    def process_client_batch(clients)
      client_ids = clients.map(&:id)

      # delete directly-related client records
      delete_custom_data_elements_with_pii(Hmis::Hud::Client, client_ids)
      @version_pruner.perform(owner: GrdaWarehouse::Hud::Client, ids: client_ids)

      delete_client_files(client_ids)
      clients.group_by(&:data_source_id).map do |data_source_id, ds_clients|
        personal_ids = ds_clients.map(&:PersonalID)
        delete_hmis_client_records(personal_ids, data_source_id)
        delete_enrollment_related_records(personal_ids, data_source_id)
      end
    end

    def delete_custom_data_elements_with_pii(model, ids)
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
        arel[:label].matches('%license number%'),
        arel[:label].matches('%policy number%'),
      ].reduce(&:or)

      scope = Hmis::Hud::CustomDataElement.with_deleted.
        where(owner_type: model.sti_name, owner_id: ids).
        joins(:data_element_definition).
        merge(Hmis::Hud::CustomDataElementDefinition.with_deleted.where(conditions))

      @version_pruner.perform(owner: Hmis::Hud::CustomDataElement, ids: scope.pluck(:id))
      scope.delete_all
    end

    def delete_enrollment_related_records(personal_ids, data_source_id)
      enrollments = GrdaWarehouse::Hud::Enrollment.
        with_deleted.
        where(data_source: data_source_id, PersonalID: personal_ids)
      return if enrollments.to_a.empty?

      enrollment_ids = enrollments.map(&:id)
      delete_custom_data_elements_with_pii(Hmis::Hud::Enrollment, enrollment_ids)
    end

    def delete_hmis_client_records(personal_ids, data_source_id)
      # delete from custom tables that may contain sensitive info
      [
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
      ].each do |model|
        scope = model.with_deleted.where(data_source_id: data_source_id, PersonalID: personal_ids)
        @version_pruner.perform(owner: model, ids: scope.map(&:id))
        scope.delete_all
      end

      # delete custom data elements from tables that may contain sensitive info
      [
        Hmis::Hud::Assessment,
        Hmis::Hud::CustomAssessment,
        Hmis::Hud::CurrentLivingSituation,
        Hmis::Hud::CustomCaseNote,
        Hmis::Hud::CustomService,
        Hmis::Hud::Enrollment,
        Hmis::Hud::Event,
        Hmis::Hud::Exit,
        Hmis::Hud::IncomeBenefit,
        Hmis::Hud::Service,
      ].each do |model|
        scope = model.with_deleted.where(data_source_id: data_source_id, PersonalID: personal_ids)
        delete_custom_data_elements_with_pii(model, scope.pluck(:id))
      end
    end

    def delete_client_files(client_ids)
      model = Hmis::File
      scope = model.with_deleted.where(client_id: client_ids)
      delete_custom_data_elements_with_pii(model, scope.pluck(:id))
      @version_pruner.perform(owner: model, ids: scope.map(&:id))
      scope.delete_all
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
