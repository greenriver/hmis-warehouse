# frozen_string_literal: true

# Service object for sanitizing untrusted user-supplied data before logging.
# Handles strings, arrays, hashes, and paths with configurable limits to prevent
# log injection attacks and excessive log volume.
#
# Usage:
#   sanitizer = Logging::Sanitizer.new
#   sanitizer.call(user_data)
#
#   # With custom limits
#   sanitizer = Logging::Sanitizer.new(max_string_length: 1000, max_hash_items: 100)
#   sanitizer.call(user_data)
#
module Logging
  class Sanitizer
    DEFAULT_MAX_STRING_LENGTH = 1_000
    DEFAULT_MAX_ARRAY_ITEMS = 100
    DEFAULT_MAX_HASH_ITEMS = 100
    DEFAULT_MAX_DEPTH = 5

    def initialize(max_string_length: DEFAULT_MAX_STRING_LENGTH, max_array_items: DEFAULT_MAX_ARRAY_ITEMS, max_hash_items: DEFAULT_MAX_HASH_ITEMS, max_depth: DEFAULT_MAX_DEPTH)
      @max_string_length = max_string_length
      @max_array_items = max_array_items
      @max_hash_items = max_hash_items
      @max_depth = max_depth
    end

    # Main entry point - automatically detects type and sanitizes accordingly
    def call(value)
      sanitize(value, current_depth: 0)
    end

    private

    def sanitize(value, current_depth:)
      case value
      when String
        sanitize_string(value)
      when Hash
        sanitize_hash(value, current_depth: current_depth)
      when Array
        sanitize_array(value, current_depth: current_depth)
      else
        value
      end
    end

    def sanitize_string(value)
      str = value.to_s
      # Remove null bytes and control characters (except newlines/tabs)
      str = str.tr("\u0000-\u0008\u000B-\u001F\u007F", '')
      # Truncate with indicator
      str.length >= @max_string_length ? str.truncate(@max_string_length, omission: '...[TRUNCATED]') : str
    end

    def sanitize_array(array, current_depth:)
      return '[MAX_DEPTH]' if current_depth >= @max_depth

      items = array.take(@max_array_items).map { |item| sanitize(item, current_depth: current_depth + 1) }
      items << "...[#{array.size - @max_array_items} more items]" if array.size > @max_array_items
      items
    end

    def sanitize_hash(hash, current_depth:)
      return '[MAX_DEPTH]' if current_depth >= @max_depth

      original_hash = hash.to_h
      result = {}

      original_hash.each do |key, value|
        break if result.size >= @max_hash_items

        sanitized_key = sanitize(key, current_depth: current_depth + 1)
        result[sanitized_key] = sanitize(value, current_depth: current_depth + 1)
      end

      result[:_truncated] = "#{original_hash.size - @max_hash_items} items hidden" if original_hash.size > @max_hash_items
      result
    end
  end
end
