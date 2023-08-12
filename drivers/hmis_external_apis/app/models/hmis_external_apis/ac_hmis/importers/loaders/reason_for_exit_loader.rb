###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ReasonForExitLoader < CustomDataElementBaseLoader
    def filename
      'ReasonForExit.csv'
    end

    protected

    def build_records
      # fixme validate that enrollment/exit ids match and are all present
      owner_id_by_exit_id = owner_class
        .where(data_source: data_source)
        .pluck(:exit_id, :id)
        .to_h
      rows.flat_map do |row|
        exit_id = row_value(row, field: 'ExitID')
        owner_id = owner_id_by_exit_id[exit_id]
        voluntary_termination_value = row_value(row, field: 'VoluntaryTermination')
        [
          new_cde_record(
            value: voluntary_termination_value,
            definition_key: :reason_for_exit_type,
          ),
          new_cde_record(
            value: row_value(row, field: 'ReasonForExit'),
            definition_key: voluntary_termination_value =~ /\Ay/i ? :reason_for_exit_voluntary : :reason_for_exit_involuntary,
          ),
          new_cde_record(
            value: row_value(row, field: 'ReasonForExitOther', required: false),
            definition_key: :reason_for_exit_other,
          ),
        ].compact_blank.each { |r| r[:owner_id] = owner_id }
      end
    end

    # FIXME- conflict in spec, assuming these CDEs are on exit, not enrollment?
    def owner_class
      Hmis::Hud::Exit
    end
  end
end
