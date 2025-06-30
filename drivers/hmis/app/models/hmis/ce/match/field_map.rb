# frozen_string_literal: true

# Routes field references to the appropriate resolver based on field naming conventions.
#
# This class acts as a dispatcher that parses field names and delegates to specialized
# resolvers. Fields without a namespace prefix default to the 'client' resolver.
#
# == Field Format
#
# Fields can be:
# - Simple: 'veteran_status' (routed to client resolver)
# - Namespaced: 'cde.custom_assessment.field_key' or 'client.dob' (routed to the cde or client resolver)
#
# For namespaced fields, the resolver name is stripped off and the remaining
# portion is passed to the resolver for further processing.
#
module Hmis::Ce::Match
  class FieldMap
    CDE = 'cde'
    CLIENT = 'client'

    def instance_value(client, field)
      resolver, resolved_field = resolver_for(field)
      resolver.instance_value(client, resolved_field)
    end

    def arel_field(field)
      resolver, resolved_field = resolver_for(field)
      resolver.arel_field(resolved_field)
    end

    # Parses a field name and returns the appropriate field type and resolved field name.
    # Used internally by resolver_for; also exposed publicly for convenience,
    # so external callers can determine the relevant form definitions for a specific match.
    #
    # @param field [String] The field name to parse
    # @return [Array<Object, String>] A tuple of [field_type, resolved_field_name]
    # @raise [ArgumentError] if the field type is not recognized
    def self.field_type_for(field)
      # Default to client field type if the field lacks namespace prefixes
      return [CLIENT, field] unless field =~ /\./

      field_type, resolved_field = field.split('.', 2)
      raise ArgumentError, "unknown resolver for \"#{field}\"" unless [CDE, CLIENT].include?(field_type)

      [field_type, resolved_field]
    end

    protected

    # Parses a field name and returns the appropriate resolver and resolved field name.
    #
    # @param field [String] The field name to parse
    # @return [Array<Object, String>] A tuple of [resolver_instance, resolved_field_name]
    # @raise [ArgumentError] if the resolver name is not recognized
    def resolver_for(field)
      field_type, resolved_field = field_type_for(field)
      resolver = registered_resolvers[field_type]

      [resolver, resolved_field]
    end

    # Registry of available field resolvers.
    def registered_resolvers
      @registered_resolvers ||= {
        CDE => Hmis::Ce::Match::CdeFieldMap.new,
        CLIENT => Hmis::Ce::Match::ClientFieldMap.new,
      }
    end
  end
end
