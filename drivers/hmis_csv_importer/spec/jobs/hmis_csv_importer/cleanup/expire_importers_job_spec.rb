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

  def run_job(retain_after_date:, retain_item_count:)
    HmisCsvImporter::Cleanup::ExpireImportersJob.new.perform(
      data_source_id: data_source.id,
      retain_item_count: retain_item_count,
      retain_after_date: retain_after_date,
    )
  end
end
