# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis_external_apis:generate_custom_assessment_forms
desc 'Generate Custom Assessment form-definition JSON from a legacy field-export CSV'
task generate_custom_assessment_forms: [:environment] do
  csv_path = ENV.fetch('CSV_PATH') { abort('Usage: CSV_PATH=/path/to/source.csv rails driver:hmis_external_apis:generate_custom_assessment_forms [ZIP=true]') }
  root = Rails.root.join('drivers/hmis_external_apis/lib/form_generation')
  result = HmisExternalApis::FormGeneration::CustomAssessmentFormGenerator.call(
    csv_path: csv_path,
    output_dir: root.join('generated-custom-assessment-forms'),
    overlay_path: root.join('overlay.yml'),
    zip: ENV['ZIP'] == 'true',
  )
  abort('Form generation failed validation') unless result[:success]

  next unless result[:zip_path]

  puts
  puts "Upload this file to Secure Files (Account > Secure Files) in the target environment: #{result[:zip_path]}"
end

# rails driver:hmis_external_apis:load_custom_assessment_forms
desc 'Publish Custom Assessment form-definition JSON directly (retires any existing published version; deletes any existing draft)'
task load_custom_assessment_forms: [:environment] do
  usage = 'Usage: ZIP_PATH=var/downloaded.zip or DIR=/path/to/json_dir rails driver:hmis_external_apis:load_custom_assessment_forms ' \
          '[DATA_SOURCE_ID=n] [DRY_RUN=true] [ONLY=id1,id2]'

  zip_path = ENV['ZIP_PATH']
  dir = ENV['DIR']
  abort(usage) if zip_path.blank? && dir.blank?

  if zip_path.present?
    require 'zip'
    abort("Zip file not found: #{zip_path}") unless File.exist?(zip_path)

    dir = Rails.root.join('tmp', "custom_assessment_forms_#{Time.current.to_i}").to_s
    FileUtils.mkdir_p(dir)
    Zip::File.open(zip_path) do |zip_file|
      zip_file.each { |entry| entry.extract(File.basename(entry.name), destination_directory: dir) }
    end
  end

  options = {
    dir: dir,
    data_source_id: ENV['DATA_SOURCE_ID'],
    dry_run: ENV['DRY_RUN'] == 'true',
    only: (ENV['ONLY'] || '').split(',').map(&:strip),
  }
  result = HmisExternalApis::FormGeneration::CustomAssessmentFormLoader.call(**options)
  abort('Load failed') unless result[:success]
end
