###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: none
# Control: no PHI, PHI is in encounter_records

module Health
  class StatusDate < HealthBase
    belongs_to :patient

    scope :engaged, -> do
      where(engaged: true)
    end

    scope :enrolled, -> do
      where(enrolled: true)
    end

    scope :enrolled_before, -> (date) do
      enrolled.where(arel_table[:date].lt(date))
    end

    scope :engaged_before, -> (date) do
      engaged.where(arel_table[:date].lt(date))
    end

    # NOTE: the following methods are used to populate and maintain the table
    # they are instance methods only to allow for useful caching
    def maintain(scope = Health::Patient)
      scope.pluck(:id).each_slice(500) do |patient_ids|
        reset_batch!

        patient_ids.each do |patient_id|
          dates = []
          all_enrollment_dates.each do |date|
            enrolled = patient_enrolled?(patient_ids, patient_id, date)
            next unless enrolled

            dates << {
              patient_id: patient_id,
              date: date,
              engaged: patient_engaged?(patient_ids, patient_id, date),
              enrolled: enrolled,
            }
          end
          self.class.transaction do
            self.class.where(patient_id: patient_id).delete_all
            self.class.import(dates)
          end
        end
      end
    end

    def reset_batch!
      @enrolled_dates = nil
      @engaged_dates = nil
    end

    def patient_enrolled?(patient_ids, patient_id, date)
      dates = enrolled_dates(patient_ids)[patient_id]
      return false unless dates.present?

      dates.include?(date)
    end

    def patient_engaged?(patient_ids, patient_id, date)
      engaged_dates(patient_ids)[date]&.include?(patient_id)
    end

    def enrolled_dates(patient_ids)
      @enrolled_dates ||= Health::Patient.preload(:patient_referrals).where(id: patient_ids).map do |patient|
        [
          patient.id,
          patient.contributed_dates,
        ]
      end.to_h
    end

    def engaged_dates(patient_ids)
      @engaged_dates ||= {}.tap do |engaged_patients|
        all_enrollment_dates.each do |date|
          engaged_patients[date] = Health::Patient.engaged(on: date).
            where(id: patient_ids).
            distinct.
            pluck(:id).
            to_set
        end
      end
    end

    def all_enrollment_dates
      @all_enrollment_dates ||= Health::PatientReferral.first_enrollment_start_date..Date.current
    end
  end
end
