###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'shared'

RSpec.describe HmisCsvImporter::Cleanup::ExpireImportersJob, type: :model do
  include_context 'HmisCsvImporter cleanup context'
  include_examples 'HmisCsvImporter cleanup record expiration'

  def records
    HmisCsvTwentyTwentyFour::Importer::Organization
  end

  def run_job(**options)
    default_options = {
      model_name: 'HmisCsvTwentyTwentyFour::Importer::Organization',
      dry_run: false,
    }
    HmisCsvImporter::Cleanup::ExpireImportersJob.new.perform(**default_options.merge(options))
  end
end
