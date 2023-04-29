###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # Utility class for MPER
  class Mper
    SYSTEM_ID = 'ac_hmis_mper'.freeze

    # @param mper_id [String]
    # @return [Hmis::Hud::Project, nil]
    def find_project_by_mper(mper_id)
      project_scope.first_by_external_id(namespace: SYSTEM_ID, id: mper_id)
    end

    # @param mper_id [String]
    # @return [Hmis::UnitType, nil]
    def find_unit_type_by_mper(mper_id)
      ::Hmis::UnitType.first_by_external_id(namespace: SYSTEM_ID, id: mper_id)
    end

    # @param source [ApplicationRecord]
    # @return [String, nil]
    def identify_source(source)
      external_ids.where(source: source).first&.value
    end

    # @param source [ApplicationRecord]
    # @param value [String]
    # @return [HmisExternalApis::ExternalId]
    def create_external_id(source:, value:)
      external_ids.create!(source: source, value: value, remote_credential: remote_credential)
    end

    protected

    def external_ids
      HmisExternalApis::ExternalId.where(namespace: SYSTEM_ID)
    end

    def project_scope
      ::Hmis::Hud::Project.where(data_source: data_source)
    end

    def remote_credential
      @remote_credential ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first!
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end
