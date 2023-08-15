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
        ret = [
          new_cde_record(
            # voluntary_termination_value is supposed to be required but is sometimes missing
            value: row_value(row, field: 'VoluntaryTermination', required: false),
            definition_key: :reason_for_exit_type,
          ),
          new_cde_record(
            value: row_value(row, field: 'ReasonForExitOther', required: false),
            definition_key: :reason_for_exit_other,
          ),
        ]

        reason_for_exit = row_value(row, field: 'ReasonForExit')
        if reason_for_exit
          ret.push new_cde_record(
            value: reason_for_exit,
            definition_key: voluntary_reason?(reason_for_exit) ? :reason_for_exit_voluntary : :reason_for_exit_involuntary,
          )
        end
        ret.compact_blank.each { |r| r[:owner_id] = owner_id }
      end
    end

    # FIXME- conflict in spec, assuming these CDEs are on exit, not enrollment?
    def owner_class
      Hmis::Hud::Exit
    end

    VOLUNTARY_REASON_MAP = {
      'Completed project' => 'Voluntary',
      'Criminal activity/destruction of property/violence' => 'Involuntary',
      'Deceased' => 'Voluntary',
      'Disagreement with rules/persons' => 'Involuntary',
      'Left for a housing opportunity before completing project' => 'Voluntary',
      'Needs could not be met by project' => 'Voluntary',
      'Non-compliance with project' => 'Involuntary',
      'Non-payment of rent/occupancy charge' => 'Involuntary',
      'Other' => 'Involuntary',
      'Reached maximum time allowed by project' => 'Involuntary',
      'Unknown/disappeared' => 'Voluntary',
    }.freeze

    def voluntary_reason?(str)
      raise "Unknown reason #{str}" unless VOLUNTARY_REASON_MAP.key?(str)

      VOLUNTARY_REASON_MAP[str] == 'Voluntary'
    end
  end
end
