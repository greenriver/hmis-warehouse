RSpec.shared_context 'hmis service setup', shared_context: :metadata do
  before(:each) do
    ::HmisUtil::ServiceTypes.seed_hud_service_types(ds1.id)
  end

  let!(:csc1) { create :hmis_custom_service_category, data_source: ds1 }
  let!(:cst1) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: csc1 }
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis service setup', include_shared: true
end
