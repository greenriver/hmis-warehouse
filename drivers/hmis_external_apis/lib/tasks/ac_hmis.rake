###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :ac_hmis do
  # rails driver:hmis_external_apis:ac_hmis:import_housing_assessments[bucket_name,s3_key,<ce_project_id>,<form_definition_identifier>]
  task :import_housing_assessments, [:bucket_name, :s3_key, :project_id, :form_definition_identifier] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled?
    next unless Rails.env.development? || HmisExternalApis::AcHmis::Mci.enabled?

    # Download the file from S3 to a tempfile, then invoke the importer
    aws = AwsS3.new(bucket_name: args.bucket_name)

    require 'tempfile'
    raise ArgumentError, 's3_key is required' if args.s3_key.blank?
    raise ArgumentError, 's3 bucket is required' if args.bucket_name.blank?

    Tempfile.create(['housing_waitlist.xlsx']) do |tmp|
      aws.fetch(file_name: args.s3_key, target_path: tmp.path)
      HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter.call(tmp.path, ce_project_id: args.project_id&.to_i, form_definition_identifier: args.form_definition_identifier, dry_run: false)
    end
  end
end
