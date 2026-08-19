###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  class UnlinkedRecordFilter
    def self.description
      'Strip Enrollment rows (and related records) with no matching Client or Project, logging what was removed'
    end

    def self.associated_model
      :"All Files"
    end

    # Keyed by class name (like `import_cleanups`' array values) rather than
    # a made-up slug, so pre_process_hooks stays consistent with the existing
    # extension-config columns.
    def self.enable
      { pre_process_hooks: { name => true } }
    end

    def self.checked?(data_source)
      data_source[:pre_process_hooks][name] || false
    end

    def self.filter!(source_dir, loadable_files, loader_log)
      allowed_personal_ids = read_column_set(source_dir, 'Client.csv', 'PersonalID')
      allowed_project_ids = read_column_set(source_dir, 'Project.csv', 'ProjectID')

      removed_enrollment_ids = filter_enrollments!(source_dir, loadable_files['Enrollment.csv'], allowed_personal_ids, allowed_project_ids, loader_log)
      return if removed_enrollment_ids.empty?

      loadable_files.each do |file_name, klass|
        next if file_name.in?(['Client.csv', 'Project.csv', 'Enrollment.csv'])
        next unless klass.hud_csv_headers.map(&:to_s).include?('EnrollmentID')

        filter_by_enrollment_id!(source_dir, file_name, klass, removed_enrollment_ids, loader_log)
      end
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

    def self.filter_enrollments!(source_dir, klass, allowed_personal_ids, allowed_project_ids, loader_log)
      file = File.join(source_dir, 'Enrollment.csv')
      return Set.new unless File.exist?(file)

      removed_enrollment_ids = Set.new
      Tempfile.create do |clean_file|
        CSV.open(clean_file, 'wb') do |csv|
          csv << CSV.parse_line(File.open(file, &:readline))
          CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
            if allowed_personal_ids.include?(row['personalid']) && allowed_project_ids.include?(row['projectid'])
              csv << row
            else
              removed_enrollment_ids << row['enrollmentid']
              reason = allowed_personal_ids.include?(row['personalid']) ? 'no_matching_project_id' : 'no_matching_personal_id'
              log_discarded_row(loader_log, 'Enrollment.csv', klass, row, reason)
            end
          end
        end
        FileUtils.mv(clean_file, file)
      end
      removed_enrollment_ids
    end
    private_class_method :filter_enrollments!

    def self.filter_by_enrollment_id!(source_dir, file_name, klass, removed_enrollment_ids, loader_log)
      file = File.join(source_dir, file_name)
      return unless File.exist?(file)

      Tempfile.create do |clean_file|
        CSV.open(clean_file, 'wb') do |csv|
          csv << CSV.parse_line(File.open(file, &:readline))
          CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
            if removed_enrollment_ids.include?(row['enrollmentid'])
              log_discarded_row(loader_log, file_name, klass, row, 'orphaned_child_record')
            else
              csv << row
            end
          end
        end
        FileUtils.mv(clean_file, file)
      end
    end
    private_class_method :filter_by_enrollment_id!

    def self.log_discarded_row(loader_log, file_name, klass, row, reason)
      ordered_values = klass.hud_csv_headers.map { |header| row[header.to_s.downcase] }
      loader_log.row_processing_notes.create!(
        file_name: file_name,
        row: ordered_values.to_csv,
        reason: reason,
      )
      loader_log.summary[file_name] ||= {}
      loader_log.summary[file_name]['total_discarded'] = (loader_log.summary[file_name]['total_discarded'] || 0) + 1
    end
    private_class_method :log_discarded_row
  end
end
