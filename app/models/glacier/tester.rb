###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This tests that we got the treehash logic right and that things appear to be
# working on some level.

require 'open3'

module Glacier
  class Tester
    def test_chunker!
      chunk_size!
      two_mb!
      four_mb!
    end

    def test_all!
      test_chunker!
      simulated_database_backup!
    end

    private

    def file_name
      File.join(Rails.root, 'app', 'models', 'glacier', 'testfile').to_s
    end

    def file_stream
      File.open(file_name)
    end

    def full_tree_hash
      'e5722743e773dd5d1e63d3de58df5deb979d51b94db6c5823f81e9866ec363ee'
    end

    def chunk_size!
      Rails.logger.info "Testing chunk size"
      begin
        Chunker.new(file_stream: file_stream, part_megs: 3)
        @here = true
      rescue
      end

      if @here
        raise "A non-power of two number of megs shouldn't be allowed"
      end

      Rails.logger.info("PASS")
    end

    def two_mb!
      Rails.logger.info "Testing 2MB behaviors"

      chunker = Chunker.new(file_stream: file_stream, part_megs: 2)
      shas = []
      chunker.each_chunk do |chunk|
        shas << chunk.digest
      end

      if shas != [ '9a76810f3694d29d82ce09051797834d443c4fb7b240fa8317315411351d4b81', '3e2187e09ee37247f5d7c7fea30f58c34b337aeecc814cbcd0c8689944b135e3' ]
        raise "Fail on 2MB, two chunks"
      end

      if chunker.digest != full_tree_hash
        raise "Fail on 2MB final digest"
      end
      Rails.logger.info("PASS")
    end

    def four_mb!
      Rails.logger.info "Testing 4MB behaviors"
      chunker = Chunker.new(file_stream: file_stream, part_megs: 4)
      chunker.each_chunk do |chunk|
        if chunk.digest != full_tree_hash
          raise "Fail on 4 meg, single chunk"
        end
      end

      if chunker.digest != full_tree_hash
        raise "Fail on 4MB final digest"
      end

      Rails.logger.info("PASS")
    end

    def simulated_database_backup!
      cmd = "cat #{file_name} | gzip"
      vault_name = "#{ENV.fetch('CLIENT')}-test-vault"
      backup = Backup.new(cmd: cmd, vault_name: vault_name)
      backup.run!
      Rails.logger.info("PASS")
    end

    # Some things you can do
    def restore!
      #utils = Utils.new
      #utils.list_archives
      #puts utils.vaults.ai
      #utils.cleanup_partial_uploads!
      #puts utils.jobs(vault_name: 'test-vault').ai
      #utils.download(vault_name: 'test-vault', archive_id: "2jvftO0hhisrm_1YA4hsBYoJrBvipPrSrgEjKSXG05g6jHDLwqwtf5yqtR6SYBFqmgqvVXKgl26-SVQdHkoPrGpIEm-Nh9ZgZaE0qDdYcqIxmZDMYdu1ZCxcLUy2aeVlzTen2FF03w")
      #utils.download(vault_name: 'test-vault', job_id: "u5kV2gPPsKBPt1hdXd-jI4gX_YQc0bKiNHwJ7mqhGj5kdwa1kkjXlTAj0SSCEuMAzV8h8MyAIhC-d4Q3n39hMC2ZjUTg")
      #utils.list_archives(vault_name: 'test-vault', job_id: "huF_5_crgyEpNhwz6eX9KKtXVkqnAX-hVnCFPmuHa9Txn_MVfVnQFByi4RYbKPYYicMVid8_ImcLfgTcr9Nl74t19Y3o")
    end
  end
end
