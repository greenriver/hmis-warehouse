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
      # The project ID is the MPER ID
      project_scope.where(ProjectID: mper_id).first
    end

    # @param mper_id [String]
    # @return [Hmis::UnitType, nil]
    def find_unit_type_by_mper(mper_id)
      ::Hmis::UnitType.first_by_external_id(namespace: SYSTEM_ID, value: mper_id)
    end

    # @param source [Hmis::Hud::Project, Hmis::UnitType]
    # @return [String, nil]
    def identify_source(source)
      case source
      when Hmis::Hud::Project
        source.ProjectID
      when Hmis::Hud::Organization
        source.OrganizationID
      when Hmis::UnitType
        external_ids.where(source: source).first&.value
      else
        source_not_supported!(source)
      end
    end

    # @param source [Hmis::UnitType]
    # @param value [String]
    # @return [HmisExternalApis::ExternalId]
    def create_external_id(source:, value:, **attrs)
      case source
      when Hmis::UnitType
        external_ids.create!(source: source, value: value, remote_credential: remote_credential, **attrs)
      else
        source_not_supported!(source)
      end
    end

    protected

    def source_not_supported!(source)
      raise "source not supported #{source.inspect}"
    end

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
