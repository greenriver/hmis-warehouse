###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  class UnlinkedRecordFilter
    NOTE_IMPORT_BATCH_SIZE = 1_000

    def self.description
      'Discard Enrollment rows with no matching Client or Project, and related records left pointing at a missing Enrollment, prior to import'
    end

    def self.associated_model
      :"All Files"
    end

    def self.enable
      { pre_process_hooks: { name => true } }
    end

    def self.checked?(data_source)
      data_source[:pre_process_hooks][name] || false
    end

    def self.filter!(source_dir, loadable_files, loader_log)
      allowed_personal_ids = read_column_set(source_dir, 'Client.csv', 'PersonalID')
      allowed_project_ids = read_column_set(source_dir, 'Project.csv', 'ProjectID')
      discarded_rows = []

      removed_enrollment_ids, kept_enrollment_ids = filter_enrollments!(
        source_dir: source_dir,
        klass: loadable_files['Enrollment.csv'],
        allowed_personal_ids: allowed_personal_ids,
        allowed_project_ids: allowed_project_ids,
        loader_log: loader_log,
        discarded_rows: discarded_rows,
      )

      loadable_files.each do |file_name, klass|
        # We already filtered Enrollment.csv
        next if file_name.in?(['Enrollment.csv'])
        # Skip any file that doesn't contain an EnrollmentID column
        next unless klass.hud_csv_headers.map(&:to_s).include?('EnrollmentID')

        filter_by_enrollment_id!(
          source_dir: source_dir,
          file_name: file_name,
          klass: klass,
          removed_enrollment_ids: removed_enrollment_ids,
          kept_enrollment_ids: kept_enrollment_ids,
          loader_log: loader_log,
          discarded_rows: discarded_rows,
        )
      end

      RowProcessingNote.import(discarded_rows, batch_size: NOTE_IMPORT_BATCH_SIZE) if discarded_rows.any?
    end

    def self.read_column_set(source_dir, file_name, column)
      file = File.join(source_dir, file_name)
      return Set.new unless File.exist?(file)

      ids = Set.new
      CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
        ids << row[column.downcase]
      end
      ids
    end
    private_class_method :read_column_set

    def self.filter_enrollments!(source_dir:, klass:, allowed_personal_ids:, allowed_project_ids:, loader_log:, discarded_rows:)
      file = File.join(source_dir, 'Enrollment.csv')
      return [Set.new, Set.new] unless File.exist?(file)

      removed_enrollment_ids = Set.new
      kept_enrollment_ids = Set.new
      Tempfile.create do |clean_file|
        CSV.open(clean_file, 'wb') do |csv|
          csv << CSV.parse_line(File.open(file, &:readline))
          CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
            if allowed_personal_ids.include?(row['personalid']) && allowed_project_ids.include?(row['projectid'])
              kept_enrollment_ids << row['enrollmentid']
              csv << row
            else
              removed_enrollment_ids << row['enrollmentid']
              reason = allowed_personal_ids.include?(row['personalid']) ? 'no_matching_project_id' : 'no_matching_personal_id'
              discarded_rows << build_discarded_row(loader_log: loader_log, file_name: 'Enrollment.csv', klass: klass, row: row, reason: reason)
            end
          end
        end
        FileUtils.mv(clean_file, file)
      end
      [removed_enrollment_ids, kept_enrollment_ids]
    end
    private_class_method :filter_enrollments!

    # removed_enrollment_ids: enrollments stripped above for having no matching Client/Project.
    # kept_enrollment_ids: every EnrollmentID that survived, i.e. is present in the cleaned Enrollment.csv.
    # A row whose EnrollmentID is in neither set points at an Enrollment that was never in this
    # import at all, rather than one this run removed.
    def self.filter_by_enrollment_id!(source_dir:, file_name:, klass:, removed_enrollment_ids:, kept_enrollment_ids:, loader_log:, discarded_rows:)
      file = File.join(source_dir, file_name)
      return unless File.exist?(file)

      Tempfile.create do |clean_file|
        CSV.open(clean_file, 'wb') do |csv|
          csv << CSV.parse_line(File.open(file, &:readline))
          CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
            enrollment_id = row['enrollmentid']
            if kept_enrollment_ids.include?(enrollment_id)
              csv << row
            elsif removed_enrollment_ids.include?(enrollment_id)
              discarded_rows << build_discarded_row(loader_log: loader_log, file_name: file_name, klass: klass, row: row, reason: 'orphaned_child_record')
            else
              discarded_rows << build_discarded_row(loader_log: loader_log, file_name: file_name, klass: klass, row: row, reason: 'orphaned_enrollment_record')
            end
          end
        end
        FileUtils.mv(clean_file, file)
      end
    end
    private_class_method :filter_by_enrollment_id!

    def self.build_discarded_row(loader_log:, file_name:, klass:, row:, reason:)
      ordered_values = klass.hud_csv_headers.map { |header| row[header.to_s.downcase] }
      loader_log.summary[file_name] ||= {}
      loader_log.summary[file_name]['total_discarded'] = (loader_log.summary[file_name]['total_discarded'] || 0) + 1

      {
        loader_log_id: loader_log.id,
        file_name: file_name,
        row: ordered_values.to_csv,
        reason: reason,
      }
    end
    private_class_method :build_discarded_row
  end
end
