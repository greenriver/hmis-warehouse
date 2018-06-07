require 'roo'
module Health::Tasks
  class ImportPatientReferrals
    FILTER_STRING = 'ASSIGNMENT_FULL'
    attr_accessor :directory, :referrals_file 
    def initialize(directory: 'var/health/referrals')
      @directory = directory
    end

    def import!
      load_unprocessed
      return if @unprocessed.empty?
      @unprocessed.each do |file_path|
        file = load_file(File.join(directory, file_path))

        Health::PatientReferralImport.create(file_name: file_path)
      end      
    end

    # Are there any ASSIGNMENT_FULL files we have not yet processed?
    def load_unprocessed
      @unprocessed = available - processed
    end

    def available
      Dir.glob("#{directory}/*/*#{FILTER_STRING}*").map{|m| m.gsub(directory, '')}
    end

    def processed
      Health::PatientReferralImport.all.pluck(:file_name)
    end

    def load_file file_path
      Roo::Spreadsheet.open(file_path)
    end

    
  end
end