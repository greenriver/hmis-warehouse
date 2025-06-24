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
    def instance_value(client, field)
      resolver, resolved_field = resolver_for(field)
      resolver.instance_value(client, resolved_field)
    end

    def arel_field(field)
      resolver, resolved_field = resolver_for(field)
      resolver.arel_field(resolved_field)
    end

    protected

    # Parses a field name and returns the appropriate resolver and resolved field name.
    #
    # @param field [String] The field name to parse
    # @return [Array<Object, String>] A tuple of [resolver_instance, resolved_field_name]
    # @raise [ArgumentError] if the resolver name is not recognized
    def resolver_for(field)
      # Default to the client resolver if the field lacks namespace prefixes
      return [registered_resolvers['client'], field] unless field =~ /\./

      resolver_name, resolved_field = field.split('.', 2)
      resolver = registered_resolvers[resolver_name]
      raise ArgumentError, "unknown resolver for \"#{field}\"" unless resolver

      [resolver, resolved_field]
    end

    # Registry of available field resolvers.
    def registered_resolvers
      @registered_resolvers ||= {
        'cde' => Hmis::Ce::Match::CdeFieldMap.new,
        'client' => Hmis::Ce::Match::ClientFieldMap.new,
      }
    end
  end
end
