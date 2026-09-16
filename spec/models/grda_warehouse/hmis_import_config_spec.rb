###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HmisImportConfig, type: :model do
  # The importer hands this password to zipcloak for a .zip upload, and zipcloak
  # re-prompts rather than failing on one it considers too long, which would
  # leave the import job waiting on a prompt nothing answers.
  describe 'zip file password length' do
    it 'accepts a password zipcloak will take' do
      config = build(:grda_warehouse_hmis_import_config, zip_file_password: 'p' * ZipCloak::MAX_PASSWORD_LENGTH)
      expect(config).to be_valid
    end

    it 'rejects a password longer than zipcloak accepts' do
      config = build(:grda_warehouse_hmis_import_config, zip_file_password: 'p' * (ZipCloak::MAX_PASSWORD_LENGTH + 1))

      expect(config).not_to be_valid
      expect(config.errors[:zip_file_password]).to be_present
    end

    it 'allows no password at all' do
      config = build(:grda_warehouse_hmis_import_config, zip_file_password: nil)
      expect(config).to be_valid
    end
  end
end
