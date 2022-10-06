RSpec.configure do |config|
  config.before(:suite) do
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
  end
end
