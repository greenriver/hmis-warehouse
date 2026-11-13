###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Finds the release tag nearest to the deployed commit and writes it to
# tmp/git_release.json for Git.release to read.
#
# Runs from docker/app/entrypoint.sh before the app boots, so it uses no Rails APIs.
class Git
  class ReleaseResolver
    REPO = ENV.fetch('GITHUB_REPO', 'greenriver/hmis-warehouse').freeze
    CACHE_PATH = '/app/tmp/git_release.json'

    # How many of the deployed commit's ancestors to search for a tag.
    # Note: Github's maximum page size is 100, so this is the maximum number of commits to search.
    LOOKBACK = 50

    class << self
      # @return [Hash, nil] { tag:, ahead:, revision: }
      def resolve(revision:)
        return nil if revision.nil? || revision.strip.empty? || revision.strip == 'unknown'

        revision = revision.strip
        ancestors = ancestor_shas(revision)
        return nil if ancestors.empty?

        # a sha's index in `ancestors` is how many commits the revision is ahead of it
        positions = {}
        ancestors.each_with_index { |sha, index| positions[sha] ||= index }

        nearest = nil
        tags.each do |tag|
          index = positions[tag[:sha]]
          next if index.nil?
          next if nearest && nearest[:ahead] <= index

          nearest = { tag: tag[:name], ahead: index, revision: revision }
        end
        nearest
      rescue StandardError
        nil
      end

      # @return [Boolean] true when a cache file was written
      def write_cache_file(revision:, path: CACHE_PATH)
        details = resolve(revision: revision)
        return false if details.nil?

        File.write(path, JSON.generate(details))
        true
      rescue StandardError
        false
      end

      # Called by docker/app/entrypoint.sh. Never raises.
      def run_from_entrypoint
        revision = read_stamp('REVISION')
        if revision.nil?
          warn 'resolve_release: no REVISION file, skipping'
          return
        end

        if write_cache_file(revision: revision)
          details = JSON.parse(File.read(CACHE_PATH))
          puts "resolve_release: #{details['tag']} (+#{details['ahead']})"
        else
          warn "resolve_release: no release tag within #{LOOKBACK} commits of the deployed " \
               'revision; no release badge will be shown'
        end
      rescue StandardError => e
        warn "resolve_release: #{e.class}: #{e.message}; no release badge will be shown"
      end

      private

      # Reads a build stamp from the app root.
      def read_stamp(name)
        path = "/app/#{name}"
        return nil unless File.exist?(path)

        value = File.read(path).chomp
        value.empty? ? nil : value
      end

      # The deployed commit and its ancestors, newest first.
      def ancestor_shas(revision)
        body = get(format('/repos/%s/commits', REPO), sha: revision, per_page: LOOKBACK, page: 1)
        return [] if body.nil?

        body.map { |commit| commit['sha'] }.compact
      end

      # Repo tags as { name:, sha: }, from up to two pages of 100. /tags is not ordered by
      # date, so every page is read.
      def tags
        list = []
        (1..2).each do |page|
          body = get(format('/repos/%s/tags', REPO), per_page: 100, page: page)
          break if body.nil?

          body.each do |tag|
            sha = tag.dig('commit', 'sha')
            list << { name: tag['name'], sha: sha } if sha
          end
          break if body.length < 100
        end
        list
      end

      # @return [Array, nil] the parsed response body, or nil if the request failed or the
      #   body was not an Array.
      def get(path, params)
        uri = URI::HTTPS.build(host: 'api.github.com', path: path, query: URI.encode_www_form(params))
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Accept'] = 'application/vnd.github+json'
          request['User-Agent'] = 'hmis-warehouse-release-resolver'
          http.request(request)
        end
        return nil unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        body.is_a?(Array) ? body : nil
      rescue StandardError
        nil
      end
    end
  end
end

# Runs only when this file is executed directly, not when required or autoloaded.
Git::ReleaseResolver.run_from_entrypoint if $PROGRAM_NAME == __FILE__
