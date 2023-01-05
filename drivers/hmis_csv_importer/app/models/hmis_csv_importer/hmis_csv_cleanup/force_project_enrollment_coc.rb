###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForceProjectEnrollmentCoc < Base
    def cleanup!
      enrollment_coc_batch = []

      enrollment_coc_scope.find_each do |e_coc|
        # Don't replace blanks
        next if e_coc.CoCCode.blank?

        # If we have a single CoC from the project, this will set it
        coc_code = coc_for(e_coc.ProjectID)
        # If they already match or we couldn't determine the project CoC, don't do anything
        next if coc_code.blank? || coc_code == e_coc.CoCCode

        e_coc.CoCCode = coc_code
        e_coc.set_source_hash
        enrollment_coc_batch << e_coc
      end

      enrollment_coc_source.import(
        enrollment_coc_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_coc_source),
          columns: [:CoCCode, :source_hash],
        },
      )
    end

    private def project_cocs
      @project_cocs ||= {}.tap do |lookup|
        importable_file_class('ProjectCoC').
          where(importer_log_id: @importer_log.id).
          pluck(:ProjectID, :CoCCode).each do |p_id, coc|
            lookup[p_id] ||= Set.new
            lookup[p_id] << coc
          end
        # only return projects where there's only one CoC
        lookup = lookup.delete_if { |_, cocs| cocs.count != 1 }.each { |k, vs| lookup[k] = vs.first }
      end

      @project_cocs
    end

    private def coc_for(project_id)
      project_cocs[project_id]
    end

    def enrollment_coc_scope
      enrollment_coc_source.
        where(importer_log_id: @importer_log.id).
        where.not(CoCCode: nil)
    end

    def enrollment_coc_source
      importable_file_class('EnrollmentCoC')
    end

    def self.description
      'Force Enrollment CoC to match Project CoC if Enrollment CoC is present'
    end

    def self.enable
      {
        import_cleanups: {
          'EnrollmentCoc': ['HmisCsvImporter::HmisCsvCleanup::ForceProjectEnrollmentCoc'],
        },
      }
    end
  end
end
