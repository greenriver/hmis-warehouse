require 'rails_helper'

RSpec.describe Health::ScheduledDocuments::EnrollmentDisenrollment, type: :model do
  let!(:cp) { create :sender }
  let!(:aco) { create :accountable_care_organization }
  let!(:scheduled_e_d_document) { create :scheduled_e_d_document, acos: [aco.id] }

  it 'delivers the zip file' do
    scheduled_e_d_document.deliver(nil)
    expect(Dir.glob("tmp/#{aco.e_d_file_prefix}*").empty?).to be false

    # Clean up files
    Dir.glob("tmp/#{aco.e_d_file_prefix}*").each do |path|
      File.delete(path)
    end
  end
end
