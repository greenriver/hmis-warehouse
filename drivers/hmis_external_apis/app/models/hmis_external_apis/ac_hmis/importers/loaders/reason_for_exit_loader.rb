###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ReasonForExitLoader < CustomDataElementBaseLoader
    def filename
      # note filename is slightly different from the spec
      'ReasonforExit.csv'
    end

    protected

    def cde_definitions_keys
      [
        :reason_for_exit_type,
        :reason_for_exit_other,
        :reason_for_exit_voluntary,
        :reason_for_exit_involuntary,
      ]
    end

    def build_records
      exit_lookup = owner_class
        .where(data_source: data_source)
        .pluck(:exit_id, :id, :enrollment_id)
        .to_h { |exit_id, pk, enrollment_id| [exit_id, [pk, enrollment_id]] }
      expected = 0
      actual = 0
      records = rows.flat_map do |row|
        expected += 1
        exit_id = row_value(row, field: 'ExitID')
        owner_id, enrollment_id = exit_lookup[exit_id]

        unless owner_id
          log_skipped_row(row, field: 'ExitID')
          next # early return
        end

        raise 'ExitID/EnrollmentID mismatch' if enrollment_id != row_value(row, field: 'EnrollmentID')

        actual += 1
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

        # reason for exit is required but blank values are present in csv
        reason_for_exit = row_value(row, field: 'ReasonForExit', required: false)
        if reason_for_exit
          ret.push new_cde_record(
            value: reason_for_exit,
            definition_key: voluntary_reason?(reason_for_exit) ? :reason_for_exit_voluntary : :reason_for_exit_involuntary,
          )
        end
        ret.compact_blank.each { |r| r[:owner_id] = owner_id }
      end.compact
      log_processed_result(expected: expected, actual: actual)
      records
    end

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
