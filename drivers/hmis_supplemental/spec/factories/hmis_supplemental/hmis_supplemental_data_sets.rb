FactoryBot.define do
  factory :hmis_supplemental_data_set, class: 'HmisSupplemental::DataSet' do
    owner_type { 'client' }
    sequence(:object_key) { |n| "object_key#{n}.csv" }
    sequence(:name) { |n| "data set #{n}" }
    field_config do
      <<~JSON
        [
          {"key":"my_str", "label":"My Str", "type":"string"},
          {"key":"my_multi_str", "label":"My Multi Str", "type":"string", "multiValued":true},
          {"key":"my_float", "label":"My Float", "type":"float"},
          {"key":"my_int", "label":"My Int", "type":"int"},
          {"key":"my_bool", "label":"My Bool", "type":"boolean"},
          {"key":"my_date", "label":"My Date", "type":"date"}
        ]
      JSON
    end
    association :remote_credential, factory: :grda_remote_s3
    association :data_source, factory: :vt_source_data_source
  end
end
