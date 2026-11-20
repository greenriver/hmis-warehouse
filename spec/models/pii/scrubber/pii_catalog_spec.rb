###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Rules for the catalog guard below.
module PiiCatalogGuard
  # Matched against the column name split into snake_case words (FirstName -> first_name).
  PII_COLUMN_PATTERN = /(\A|_)(first_name|last_name|middle_name|ssn|dob|date_of_birth|birth_date|birthdate|emails?|phones?|cell|mobile|fax|city|address|street\d*|zip(code)?\d*|postal)(_|\z)/

  # Columns that match the pattern but hold a flag, count, code, or secret instead of a value.
  NON_VALUE_PATTERN = Regexp.union(
    /(dob|ssn)_(data_)?(quality|complete|missing|not_collected|partial|refused|after_entry_date|error_count|error_rate)/, # data-quality measures
    /(\A|_)(to|from|previous|in)_street(_essh|_es_sh|_last_night)?\z|(\A|_)street_(essh|es_sh|outreach|last_night)(_|\z)/, # homelessness history, not an address
    /\At_cell_|report_cell_id|\Acell_name\z/, # HUD report cell counts and references
    /\Aaddress_(data_quality|type|id)\z|_address_type\z|plan_to_address_barriers/, # address metadata, not an address
    /\Aip_address\z/, # network address, not a postal address
    /_iv\z/, # encryption initialization vectors
    /zip_(file|password)|encrypted_zip/, # archive files and their passwords
    /\Acan_view_|show_partial_ssn|dob_selection_method|email_(type|schedule)|default_lms_email|exclude_phone/, # settings and permissions
  )

  # Allowed by [table, column].
  ALLOWED = {
    ['eccovia_case_managers', 'first_name'] => 'staff directory',
    ['eccovia_case_managers', 'last_name'] => 'staff directory',
    ['eccovia_case_managers', 'email'] => 'staff directory',
    ['eccovia_case_managers', 'phone'] => 'staff directory',
    ['eccovia_case_managers', 'cell'] => 'staff directory',
    ['longitudinal_spm_results', 'cell'] => 'report cell label',
    ['eto_api_configs', 'email'] => 'integration account',
    ['external_reporting_cohort_permissions', 'email'] => 'user access grant',
    ['external_reporting_project_permissions', 'email'] => 'user access grant',
    ['configs', 'support_contact_email'] => 'system configuration',
    ['financial_providers', 'zip_code'] => 'vendor address',
    ['financial_providers', 'address_line_1'] => 'vendor address',
    ['financial_providers', 'address_line_2'] => 'vendor address',
    ['financial_providers', 'city'] => 'vendor address',
    ['financial_providers', 'service_provider_area_by_city'] => 'vendor service area',
    ['hud_report_hic_project_cocs', 'Zip'] => 'project site address',
    ['hud_report_hic_project_cocs', 'City'] => 'project site address',
    ['ma_monthly_performance_projects', 'city'] => 'project site address',
    ['hud_report_instances', 'zip_file'] => 'attached report file, not scrubbed (level 4)',
    ['import_logs', 'zip'] => 'import file reference',
    ['account_requests', 'email'] => 'prospective staff user',
    ['account_requests', 'first_name'] => 'prospective staff user',
    ['account_requests', 'last_name'] => 'prospective staff user',
    ['account_requests', 'phone'] => 'prospective staff user',
    ['youth_intakes', 'owns_cell_phone'] => 'boolean flag',
    ['users', 'talent_lms_email'] => 'staff account; the users table is excluded from scrubbing',
    ['login_activities', 'city'] => 'staff login location',
    ['Geography', 'City'] => 'project geography, not client data',
    ['Geography', 'ZIP'] => 'project geography, not client data',
  }.freeze

  # Allowed by [table pattern, column], for tables repeated per HMIS CSV year.
  PROJECT_COC_TABLE = /(\A|_)project_?cocs?\z/i
  SITE_TABLE = /(\A|_)sites?\z/i
  EXIT_TABLE = /(\A|_)exits?\z/i
  EXPORT_TABLE = /(\A|_)exports?\z/i
  ALLOWED_BY_TABLE_PATTERN = {
    [PROJECT_COC_TABLE, 'City'] => 'project site address',
    [PROJECT_COC_TABLE, 'ZIP'] => 'project site address',
    [PROJECT_COC_TABLE, 'Zip'] => 'project site address',
    [PROJECT_COC_TABLE, 'deleted_zip_override'] => 'project site address override',
    [SITE_TABLE, 'City'] => 'project site address',
    [SITE_TABLE, 'ZIP'] => 'project site address',
    [EXIT_TABLE, 'EmailSocialMedia'] => 'integer HUD follow-up code',
    [EXPORT_TABLE, 'SourceContactEmail'] => 'data source contact person, not a client',
    [EXPORT_TABLE, 'SourceContactPhone'] => 'data source contact person, not a client',
  }.freeze

  def self.tokenized(column)
    column.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end

  def self.pii_named?(column)
    words = tokenized(column)
    PII_COLUMN_PATTERN.match?(words) && !NON_VALUE_PATTERN.match?(words)
  end

  def self.allowed?(table, column)
    ALLOWED.key?([table, column]) ||
      ALLOWED_BY_TABLE_PATTERN.keys.any? { |pattern, name| name == column && pattern.match?(table) }
  end
end

# A column whose name looks like PII must be declared with pii_attr on a model
# for its table, or be allow-listed in PiiCatalogGuard with a reason. Covers the
# warehouse, reporting and app databases. Tables without a model are not checked,
# and neither are views, because their data comes from base tables.
RSpec.describe 'PII attribute catalog' do
  def declared_columns(model)
    model.pii_attributes_config.keys.map { |name| (model.attribute_aliases[name.to_s] || name).to_s }
  end

  # Returns [violations, checked], both lists of "db: table.column".
  def scan
    Rails.application.eager_load! unless Rails.application.config.eager_load

    results = [GrdaWarehouseBase, ReportingBase, ApplicationRecord].map do |base|
      db_name = base.connection_db_config.name
      models = ActiveRecord::Base.descendants.select do |model|
        !model.abstract_class? &&
          model.name&.safe_constantize == model &&
          model.connection_db_config.name == db_name &&
          model.table_exists? &&
          !model.connection.view_exists?(model.table_name)
      end

      violations = []
      checked = []
      models.group_by(&:table_name).each do |table, table_models|
        declared = table_models.flat_map { |model| model.try(:stores_pii?) ? declared_columns(model) : [] }
        table_models.first.column_names.each do |column|
          next unless PiiCatalogGuard.pii_named?(column)

          label = "#{db_name}: #{table}.#{column}"
          checked << label
          violations << label unless declared.include?(column) || PiiCatalogGuard.allowed?(table, column)
        end
      end
      [violations, checked]
    end

    [results.flat_map(&:first), results.flat_map(&:last)]
  end

  describe PiiCatalogGuard do
    describe '.pii_named?' do
      ['LastPermanentZIP', 'FirstName', 'cell', 'city', 'LastPermanentCity', 'address_line_1', 'MsgPhone', 'client_email'].each do |column|
        it "flags #{column}" do
          expect(described_class.pii_named?(column)).to be(true)
        end
      end

      ['TCellCount', 'dob_data_quality', 'report_cell_id', 'previous_street_essh', 'AddressDataQuality', 'ip_address', 'ssn_iv'].each do |column|
        it "ignores #{column}" do
          expect(described_class.pii_named?(column)).to be(false)
        end
      end

      it 'does not skip a value column that contains a non-value fragment' do
        expect(described_class.pii_named?('previous_street_address')).to be(true)
        expect(described_class.pii_named?('cell_name_alias')).to be(true)
      end
    end

    describe '.allowed?' do
      it 'matches a [table, column] entry only on that table' do
        expect(described_class.allowed?('Geography', 'City')).to be(true)
        expect(described_class.allowed?('Client', 'City')).to be(false)
      end

      it 'matches table patterns only on the named column' do
        expect(described_class.allowed?('hmis_2024_project_cocs', 'City')).to be(true)
        expect(described_class.allowed?('hmis_2024_project_cocs', 'email')).to be(false)
        expect(described_class.allowed?('hmis_2024_enrollments', 'City')).to be(false)
        expect(described_class.allowed?('hmis_2024_exits', 'EmailSocialMedia')).to be(true)
        expect(described_class.allowed?('Client', 'EmailSocialMedia')).to be(false)
      end
    end
  end

  it 'has pii_attr or an allow-list reason for every PII-named column on a modeled table' do
    violations, _checked = scan

    expect(violations.sort).to eq([])
  end

  it 'checks known columns in each database and skips views' do
    _violations, checked = scan

    expect(checked).to include(
      'warehouse: Client.FirstName',
      'warehouse: Enrollment.LastPermanentCity',
      'warehouse: eccovia_case_managers.cell',
      'reporting: warehouse_data_quality_report_enrollments.first_name',
      'primary: login_activities.city',
    )
    expect(checked).not_to include('warehouse: report_enrollments.LastPermanentCity', 'warehouse: Site.City')
  end
end
