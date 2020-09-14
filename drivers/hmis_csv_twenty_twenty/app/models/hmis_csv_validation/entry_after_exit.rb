###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::EntryAfterExit < HmisCsvValidation::Validation
  def self.check_validity!(klass, importer_log, _options)
    e_t = HmisCsvTwentyTwenty::Importer::Enrollment.arel_table
    ex_t = HmisCsvTwentyTwenty::Importer::Exit.arel_table
    incorrect_ids = klass.joins(:exit).
      where(importer_log_id: importer_log.id).
      where(e_t[:EntryDate].gteq(ex_t[:ExitDate])).
      pluck(:EnrollmentID)
    return [] if incorrect_ids.empty?

    failures = []
    klass.where(
      importer_log_id: importer_log.id,
      EnrollmentID: incorrect_ids,
    ).find_each do |item|
      failures << new(
        importer_log_id: importer_log.id,
        source_id: item.source_id,
        source_type: item.source_type,
        status: 'Enrollment Entry Date is on or after Exit Date',
      )
    end
    failures
  end
end
