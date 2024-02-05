###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'hmis base setup', shared_context: :metadata do
  include_context 'with paper trail'

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { create :hmis_hud_user, data_source: ds1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }

  # Custom Service Category and Custom Service Type
  let!(:csc1) { create :hmis_custom_service_category, data_source: ds1, user: u1 }
  let!(:cst1) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: csc1, user: u1 }

  let(:form_item_fragment) do
    <<~GRAPHQL
      #{scalar_fields(Types::Forms::FormItem)}
      pickListOptions {
        #{scalar_fields(Types::Forms::PickListOption)}
      }
      bounds {
        #{scalar_fields(Types::Forms::ValueBound)}
      }
      enableWhen {
        #{scalar_fields(Types::Forms::EnableWhen)}
      }
      initial {
        #{scalar_fields(Types::Forms::InitialValue)}
      }
      mapping {
        #{scalar_fields(Types::Forms::FieldMapping)}
      }
      autofillValues {
        #{scalar_fields(Types::Forms::AutofillValue)}
        autofillWhen {
          #{scalar_fields(Types::Forms::EnableWhen)}
        }
      }
    GRAPHQL
  end

  let(:form_definition_fragment) do
    <<~GRAPHQL
      #{scalar_fields(Types::Forms::FormDefinition)}
      definition {
        item {
          #{form_item_fragment}
          item {
            #{form_item_fragment}
            item {
              #{form_item_fragment}
              item {
                #{form_item_fragment}
              }
            }
          }
        }
      }
    GRAPHQL
  end
end

RSpec.shared_context 'with paper trail', shared_context: :metadata do
  before(:all) do
    @paper_trail_was = PaperTrail.enabled?
    PaperTrail.enabled = true
  end
  after(:all) do
    PaperTrail.enabled = @paper_trail_was
  end
end

RSpec.shared_context 'hmis service setup', shared_context: :metadata do
  before(:each) do
    ::HmisUtil::ServiceTypes.seed_hud_service_types(ds1.id)
  end

  let!(:csc1) { create :hmis_custom_service_category, data_source: ds1, user: u1 }
  let!(:cst1) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: csc1, user: u1 }
end

RSpec.shared_context 'file upload setup', shared_context: :metadata do
  let!(:tag) do
    GrdaWarehouse::AvailableFileTag.create!(
      name: 'Birth Certificate',
      group: 'Citizenship Verification',
      included_info: 'DoB, citizenship',
    )
  end

  let!(:tag2) do
    GrdaWarehouse::AvailableFileTag.create!(
      name: 'Social Security Card',
      group: 'Citizenship Verification',
      included_info: 'SSN',
    )
  end

  let!(:file) { File.open('drivers/hmis/spec/fixtures/files/TEST_PDF.pdf') }
  let!(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: 'TEST_PDF.pdf',
      content_type: 'application/pdf',
    )
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis base setup', include_shared: true
end
