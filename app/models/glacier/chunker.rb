###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html
#
# Large backups get broken into individual files and uploaded individually.
# During this process, we use a specified algorithm, implemented below, to calculate
# hashes/fingerprints/digests of each piece and the entire upload. I think "checksum"
# isn't the right term, but ignore that.

require 'digest'

module Glacier
  class Chunker
    attr_reader :file_stream
    attr_accessor :digest, :part_size, :archive_size

    MEG = 2 ** 20

    Chunk = Struct.new(:body, :digest, :range)

    def initialize file_stream:, part_megs: 16
      exponent = Math.log2(part_megs)
      if (exponent.to_i - exponent) != 0
        raise "part_megs must be a power of two"
      end

      # each multi-part upload will be 16MB with the possible exception
      # of the last one which can be smaller. This number must be a power
      # of 2.
      self.part_size = part_megs * MEG

      @file_stream = file_stream
    end

    def each_chunk
      shas = []
      self.archive_size = 0

      beginning_byte = 0
      start_time = Time.now
      while chunk = file_stream.read(part_size)
        Rails.logger.info "Processing chunk; elapsed time: #{(Time.now - start_time)} seconds"
        chunk_shas = _get_chunk_shas(chunk)
        # Rails.logger.info "SHAing chunk; elapsed time: #{(Time.now - start_time)} seconds"
        self.archive_size += chunk.length

        tree_hash = _get_treehash(chunk_shas)
        # Rails.logger.info "Tree Hash chunk; elapsed time: #{(Time.now - start_time)} seconds"
        shas << tree_hash

        ending_byte = beginning_byte+chunk.length-1
        range = "bytes #{beginning_byte}-#{ending_byte}/*"

        yield(Chunk.new(chunk, _sha_as_string(tree_hash), range))
        # Rails.logger.info "Chunk yielded; elapsed time: #{(Time.now - start_time)} seconds"
        beginning_byte += chunk.length
        start_time = Time.now
      end

      # Entire multi-part digest
      self.digest = _sha_as_string(_get_treehash(shas))
    end

    private

    def _sha_as_string sha256
      sha256.each_char.to_a.flat_map { |x| "%02x" % x.unpack('C') }.join
    end

    def _get_chunk_shas(chunk)
      offset = 0
      shas = []
      while offset < chunk.length
        shas << Digest::SHA256.digest(chunk.byteslice(offset, MEG))

        Rails.logger.debug { _sha_as_string(shas.last) + " " + offset.to_s + "-" + (offset+MEG-1).to_s }

        offset += MEG
      end

      shas
    end

    def _get_treehash(shas)
      while shas.length > 1
        shas = shas.
          each_slice(2).
          map(&:join).
          map { |x| x.length == 32 ? x : Digest::SHA256.digest(x) }
      end

      shas.first
    end
  end
end
