require 'rails_helper'

RSpec.describe ClaimsReporting::Importer do
  let(:importer) { described_class.new }

  describe '#import_from_zip' do
    # This will test the actual functionality with minimal sample data
    let(:zip_path) { Rails.root.join('drivers', 'claims_reporting', 'spec', 'fixtures', 'test_claims.zip') }
    let(:fixtures_dir) { Rails.root.join('drivers', 'claims_reporting', 'spec', 'fixtures') }

    # Create valid CSV content for each model based on its schema
    let(:member_roster_csv) do
      headers = ["member_id", "nam_first", "nam_last", "sex", "date_of_birth", "enrolled_flag", "last_office_visit", "last_ed_visit", "last_ip_visit", "cp_claim_dt"]
      data = [
        ["test1234", "Test", "User", "M", "1980-01-01", "Y", "2024-03-20", "2024-03-15", "2024-03-10", "2024-03-05"]
      ]

      CSV.generate(col_sep: '|') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end

    before do
      # Create a test zip file with CSV data - just one file to keep it simple
      FileUtils.mkdir_p(fixtures_dir)

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        zipfile.get_output_stream("member_roster.csv") { |f| f.write(member_roster_csv) }
      end
    end

    after do
      # Clean up test files
      FileUtils.rm_f(zip_path)

      # Clean up any test data we created
      ClaimsReporting::MemberRoster.where(member_id: "test1234").delete_all
    end

    it 'imports data from a zip file' do
      # First, create an import record
      import = ClaimsReporting::Import.create!(
        source_url: "file://#{zip_path}",
        started_at: Time.current,
        importer: "ClaimsReporting::Importer",
        method: "import_from_zip",
        args: { replace_all: true }
      )

      importer.instance_variable_set(:@import, import)

      results = importer.import_from_zip(zip_path, new_import: false, replace_all: true)

      # Check basic results
      expect(results.keys).to include("member_roster.csv")

      # Verify data was read
      expect(results["member_roster.csv"][:records_read]).to be > 0
    end
  end
end
