module Importing
  class RunHealthImportJob < ActiveJob::Base

    def perform
      Health::Tasks::ImportEpic.new.run!
      Health::Tasks::PatientClientMatcher.new.run!
    end

  end
end