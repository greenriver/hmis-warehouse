###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

## MPER (to be removed)
#
# Note: this class may still be used for external ID lookups even if the MPER credential is no longer active.
# See issues #8143 and #8142 for plan to sunset MPER and LINK integrations.
module HmisExternalApis::AcHmis
  # Utility class for MPER
  class Mper
    SYSTEM_ID = 'ac_hmis_mper'

    # @param mper_id [String]
    # @return [Hmis::Hud::Project, nil]
    def find_project_by_mper(mper_id)
      # The project ID is the MPER ID
      project_scope.where(ProjectID: mper_id).first
    end

    # Whether the MPER Projects Importer integration is enabled
    def self.enabled?
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).any?
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
    # only used for testing
    def create_external_id(source:, value:, **attrs)
      case source
      when Hmis::UnitType
        external_ids.create!(source: source, value: value, remote_credential: remote_credential, **attrs)
      else
        source_not_supported!(source)
      end
    end

    def self.external_ids
      HmisExternalApis::ExternalId.where(namespace: SYSTEM_ID)
    end

    def external_ids
      self.class.external_ids
    end

    protected

    def source_not_supported!(source)
      raise "source not supported #{source.inspect}"
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
