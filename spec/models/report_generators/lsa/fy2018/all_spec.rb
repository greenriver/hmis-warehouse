require 'rails_helper'

RSpec.describe ReportGenerators::Lsa::Fy2018::All, type: :model do
  describe 'When running an LSA' do
    # NOTE: spec_helper.rb defines ENV['NO_LSA_RDS']='true', which prevents
    # auto connection to RDS
    let(:report) { ReportGenerators::Lsa::Fy2018::All.new }
    let!(:lsa) { create :lsa_fy2018 }
    let!(:report_result) { create :report_result, report_id: lsa.id }
    it "doesn't throw an error when checking the sample code" do
      report.start_report(Reports::Lsa::Fy2018::All.first)
      expect { report.validate_lsa_sample_code }.to_not raise_error
    end
  end
end
