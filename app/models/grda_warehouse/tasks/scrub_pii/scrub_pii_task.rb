###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  class ScrubPiiTask
    attr_accessor :replacement

    def self.perform(...)
      new.perform(...)
    end

    REPLACEMENTS = {
      null_or_identifier: NullReplacement,
      fakes: FakeReplacement,
      identifier: IdentifierReplacement,
    }.freeze

    def perform(client_ids:, data_source_ids:, mode:, prng_seed: nil)
      Faker::Config.random = Random.new(prng_seed) if prng_seed
      replacement = REPLACEMENTS.fetch(mode)

      client_scope(client_ids: client_ids, data_source_ids: data_source_ids).find_in_batches do |clients|
        scrub_clients(clients)
        delete_versions(GrdaWarehouse::Hud::Client, clients.map(&:id))
        delete_hmis_client_records(clients)

        enrollments = GrdaWarehouse::Hud::Enrollment.joins(:client).merge(clients)
        scrub_enrollments(enrollments)
        delete_hmis_enrollment_records(enrollments)
        delete_versions(GrdaWarehouse::Hud::Enrollments, enrollments.map(&:id))
      end
    end

    protected

    def scrub_clients(clients)
      values = clients.map do |client|
        replacement.client_attrs(client).merge(id: client.id)
      end

      GrdaWarehouse::Hud::Client.import(
        values,
        on_duplicate_key_update: {conflict_target: [:id], columns: values.first.keys},
      )
    end

    def scrub_enrollments(enrollments)
      return if enrollments.empty?
      values = enrollments.map do |enrollment|
        replacement.enrollment_attrs(enrollment).merge(id: enrollment.id)
      end
      GrdaWarehouse::Hud::Enrollment.import(
        values,
        on_duplicate_key_update: {conflict_target: [:id], columns: values.first.keys},
      )
    end

    def delete_hmis_enrollment_records(clients)
      #recent_report_enrollments
      # report enrollments
      # youth_case_managements
      # youth_follow_ups
      # youth_intakes
      raise
    end

    def delete_hmis_client_records(clients)
      client_ids = clients.map(&:id)
      [
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
      ].each do |klass|
        scope = klass.where(client_id: client_ids)
        delete_versions(klass, scope.pluck(:id))
        scope.delete_all
      end
    end


    def column_nullable?(record, field)
      record.class.columns_hash[column_name.to_s]&.null
    end

    def delete_versions(item_type, item_ids)
      GrdaWarehouse::Version.where(item_type: item_type, item_id: item_ids).delete_all
    end

    def client_scope(client_ids: nil, data_source_ids: nil)
      scope = GrdaWarehouse::Hud::Client
      scope = scope.where(id: client_ids) if client_ids
      scope = scope.where(data_source_id data_source_ids) if data_source_ids
      scope
    end
  end
end
