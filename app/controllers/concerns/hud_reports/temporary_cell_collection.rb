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

    def count(attribute = nil)
      if attribute && @group_attributes
        # Group by multiple attributes and count by the specified attribute
        grouped_counts = {}
        @objects.each do |obj|
          # Create a key from the grouping attributes
          group_key = @group_attributes.map { |attr| obj.send(attr) }
          grouped_counts[group_key] ||= 0
          grouped_counts[group_key] += 1
        end
        grouped_counts
      elsif attribute
        # Count by single attribute (no grouping)
        grouped_counts = {}
        @objects.each do |obj|
          key = obj.send(attribute)
          grouped_counts[key] ||= 0
          grouped_counts[key] += 1
        end
        grouped_counts
      else
        # Simple count of all objects
        @objects.count
      end
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

    def any?(&block)
      if block_given?
        @objects.any?(&block)
      else
        @objects.any?
      end
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

    def to_a
      # Convert to array for operations like +=
      @objects.to_a
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
      # Handle both hash conditions and Arel conditions
      filtered = @objects.select do |obj|
        case conditions
        when Hash
          # Simple hash conditions
          conditions.all? do |key, value|
            obj.send(key) == value
          end
        when Arel::Nodes::Node
          # Arel conditions - we need to evaluate them against the object
          evaluate_arel_condition(conditions, obj)
        else
          # Unknown condition type - skip filtering
          true
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

    def group(*attributes)
      # Store the grouping attributes for use in count
      @group_attributes = attributes
      self
    end

    private

    def evaluate_arel_condition(condition, obj)
      case condition
      when Arel::Nodes::Equality
        # Handle equality conditions like a_t[:field].eq(value)
        field_name = condition.left.name.to_s
        expected_value = condition.right
        obj.send(field_name) == expected_value
      when Arel::Nodes::GreaterThan
        # Handle greater than conditions like a_t[:field].gt(value)
        field_name = condition.left.name.to_s
        expected_value = condition.right
        obj.send(field_name) > expected_value
      when Arel::Nodes::GreaterThanOrEqual
        # Handle greater than or equal conditions like a_t[:field].gteq(value)
        field_name = condition.left.name.to_s
        expected_value = condition.right
        obj.send(field_name) >= expected_value
      when Arel::Nodes::LessThan
        # Handle less than conditions like a_t[:field].lt(value)
        field_name = condition.left.name.to_s
        expected_value = condition.right
        obj.send(field_name) < expected_value
      when Arel::Nodes::LessThanOrEqual
        # Handle less than or equal conditions like a_t[:field].lteq(value)
        field_name = condition.left.name.to_s
        expected_value = condition.right
        obj.send(field_name) <= expected_value
      when Arel::Nodes::In
        # Handle IN conditions like a_t[:field].in([value1, value2])
        field_name = condition.left.name.to_s
        expected_values = condition.right
        expected_values.include?(obj.send(field_name))
      when Arel::Nodes::And
        # Handle AND conditions
        condition.children.all? { |child| evaluate_arel_condition(child, obj) }
      when Arel::Nodes::Or
        # Handle OR conditions
        condition.children.any? { |child| evaluate_arel_condition(child, obj) }
      else
        # For other Arel conditions, skip filtering for now
        true
      end
    rescue NoMethodError
      # If the object doesn't respond to the method, skip filtering
      true
    end
  end
end
