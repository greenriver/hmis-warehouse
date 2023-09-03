###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ClientValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :Gender,
    :Race,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Client.hmis_configuration(version: '2024').except(*IGNORED)
  end

  def self.hmis_validate(record, options: {}, role: nil, **_kwargs)
    errors = HmisErrors::Errors.new
    errors.add :dob, :out_of_range, severity: :error, message: future_message, **options if record.dob&.future?
    errors.add :dob, :invalid, severity: :error, **options if record.dob && record.dob < (Date.current - 120.years)

    # If validating client form submission, and MCI API enabled, validate presence of MCI.
    if role&.to_sym == :CLIENT && HmisExternalApis::AcHmis::Mci.enabled?
      has_mci = record.ac_hmis_mci_ids.exists? || record.create_mci_id
      if !has_mci && record.persisted?
        # MCI clearance is required UNLESS client is enrolled at any Street Outreach or ES NBN projects
        so_or_nbn_enrollments = record.enrollments.with_project_type([1, 4])
        errors.add :mci_id, :required, readable_attribute: 'MCI ID', **options unless so_or_nbn_enrollments.exists?
      end
    end
    errors.errors
  end

  def validate(record)
    super(record) do
      record.errors.add :gender, :required if !skipped_attributes(record).include?(:gender) && ::HudUtility2024.gender_id_to_field_name.except(8, 9, 99).values.any? { |field| record.send(field).nil? }
      record.errors.add :race, :required if !skipped_attributes(record).include?(:race) && ::HudUtility2024.races.except('RaceNone').keys.any? { |field| record.send(field).nil? }

      # Validate exactly 1 primary name
      if record.names.any?
        num_primary_names = record.names.reject(&:marked_for_destruction?).map(&:primary).count(true)
        record.errors.add :names, :invalid, full_message: 'One primary name is required' if num_primary_names != 1
      end
    end
  end
end
