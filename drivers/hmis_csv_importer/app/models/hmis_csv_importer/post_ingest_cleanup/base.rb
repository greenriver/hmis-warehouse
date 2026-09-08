###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Base class for cleanups that run *after* ingest! against warehouse data
# (not the staging tables that HmisCsvCleanup::Base operates on).
#
# These reuse the same import_cleanups jsonb config and Importer Extensions UI
# as the pre-ingest cleanups (config/UI class methods are inherited from
# HmisCsvCleanup::Base), but are invoked in the importer's post_ingest_cleanup!
# phase and are given the data source and the involved HUD ProjectIDs so they
# can scope their work to the projects covered by the import.
module HmisCsvImporter::PostIngestCleanup
  class Base < HmisCsvImporter::HmisCsvCleanup::Base
    attr_accessor :data_source, :project_ids

    def initialize(importer_log:, data_source:, project_ids:, version:)
      @importer_log = importer_log
      @data_source = data_source
      @project_ids = project_ids
      @current_version = version
    end

    def self.post_ingest?
      true
    end
  end
end
