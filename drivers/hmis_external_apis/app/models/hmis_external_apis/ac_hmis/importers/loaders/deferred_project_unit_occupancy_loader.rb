###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class DeferredProjectUnitOccupancyLoader < BaseLoader
    include Hmis::Concerns::HmisArelHelper

    def initialize(tracker:, clobber:)
      super(reader: nil, tracker: tracker, clobber: clobber)
    end

    def runnable?
      super && tracker.assignments.any?
    end

    def perform
      enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
      scoped_records = model_class.where(enrollment_id: enrollments.select(:id))
      # destroy all existing records
      scoped_records.destroy_all if clobber
      ar_import(model_class, build_records, recursive: true)
    end

    protected

    def build_records
      exit_dates_by_pk = Hmis::Hud::Exit
        .where(data_source: data_source)
        .joins(:enrollment)
        .pluck(e_t[:id], :exit_date)
      rows.map do |row|
        unit_id, enrollment_id, start_date = row.fetch_values(:unit_id, :enrollment_id, :start_date)
        record = model_class.new(unit_id: unit_id, enrollment_id: enrollment_id)
        record.build_occupancy_period(
          start_date: start_date || today,
          end_date: exit_dates_by_pk[enrollment_id],
          user_id: system_user_pk,
        )
        record
      end
    end

    def rows
      tracker.assignments.values
    end

    def model_class
      Hmis::UnitOccupancy
    end
  end
end
