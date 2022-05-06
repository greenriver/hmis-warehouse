###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 confidential setup', shared_context: :metadata do
  FactoryBot.reload

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, exporter.file_name_for(klass))
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 confidential setup', include_shared: true
end
