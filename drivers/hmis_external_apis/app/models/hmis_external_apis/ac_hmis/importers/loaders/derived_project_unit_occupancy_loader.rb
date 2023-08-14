###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class DerivedProjectUnitOccupancyLoader < BaseLoader
    def initialize(tracker:, clobber: true)
      @clobber = clobber
      @tracker = tracker
    end

    def data_file_provided?
      tracker.assignments.any?
    end

    def perform
      enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
      scoped_records = model_class.where(enrollment_id: enrollments.select(:id))
      if clobber
        # destroy all existing records
        scoped_records.destroy_all
      else
        # there's no unique key on occupancies so we have to destroy and reimport
        # destroy only occupancies referenced by enrollments
        rows.map { |h| h[:enrollment_id] }.uniq.in_groups_of(1_000).each do |enrollment_pks|
          scoped_records.active.where(enrollment_id: enrollment_pks).destroy_all
        end
        model_class.where(enrollment_id: enrollments.select(:id)).destroy_all
      end
      model_class.import(build_records, validate: false, recursive: true, batch_size: 1_000)
    end

    def table_names
      [model_class.table_name, Hmis::ActiveRange.table_name]
    end

    protected

    def build_records
      rows.map do |row|
        unit_id, enrollment_id, start_date = row.fetch_values(:unit_id, :enrollment_id, :start_date)
        record = model_class.new(unit_id: unit_id, enrollment_id: enrollment_id)
        record.build_occupancy_period(start_date: start_date || today, user_id: system_user_id)
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
