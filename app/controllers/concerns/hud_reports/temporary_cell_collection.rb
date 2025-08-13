###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Temporary collection class that behaves like ActiveRecord::Relation for cell data loaded from S3
  class TemporaryCellCollection
    include Enumerable

    def initialize(objects)
      @objects = objects
    end

    def each(&block)
      @objects.each(&block)
    end

    def count
      @objects.count
    end

    def size
      @objects.size
    end

    def length
      @objects.length
    end

    def empty?
      @objects.empty?
    end

    def blank?
      @objects.blank?
    end

    def present?
      @objects.present?
    end

    def any?
      @objects.any?
    end

    def find_each(&block)
      @objects.each(&block)
    end

    def preload(*_associations)
      # Mock preload - just return self since associations are already loaded
      self
    end

    def distinct
      # Mock distinct - just return self since we're already unique
      self
    end

    def map(&block)
      @objects.map(&block)
    end

    def pluck(*attributes)
      @objects.map do |obj|
        attributes.map { |attr| obj.send(attr) }
      end
    end

    def where(conditions = {})
      # Mock where - filter objects based on conditions
      filtered = @objects.select do |obj|
        conditions.all? do |key, value|
          obj.send(key) == value
        end
      end
      TemporaryCellCollection.new(filtered)
    end

    def joins(*_associations)
      # Mock joins - just return self since associations are already loaded
      self
    end

    def merge(_scope)
      # Mock merge - just return self
      self
    end
  end
end
