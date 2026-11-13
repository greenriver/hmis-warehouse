###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Benchmarking
  # Identifies a benchmark dataset: a directory of HMIS CSV files, either at
  # the path itself or in a source/ subdirectory (the spec-fixture layout).
  # The content hash keys benchmark results to the exact input data so results
  # from different runs are only compared when the inputs match.
  class Dataset
    attr_reader :path

    def initialize(path)
      @path = path.to_s
    end

    def name
      File.basename(path)
    end

    def csv_dir
      source = File.join(path, 'source')
      return source if File.directory?(source)

      path
    end

    def content_hash
      @content_hash ||= begin
        digest = Digest::MD5.new
        Dir.children(csv_dir).sort.each do |entry|
          file = File.join(csv_dir, entry)
          next unless File.file?(file)

          digest.update(entry)
          digest.update(Digest::MD5.file(file).hexdigest)
        end
        digest.hexdigest
      end
    end

    def to_h
      {
        name: name,
        path: path,
        content_hash: content_hash,
      }
    end
  end
end
