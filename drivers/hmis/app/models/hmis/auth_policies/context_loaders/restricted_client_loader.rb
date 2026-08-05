###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Resolves which restricted clients are hidden from the user, in bulk.
#
# Keyed by both client_id and enrollment_id because Enrollment has no client_id column; it reaches
# Client through a composite [data_source_id, PersonalID] association. The
# hmis_restricted_client_enrollments view carries both keys on the same row, so an enrollment can be
# resolved without loading its client.
#
# Only restricted clients appear in the view, so anything absent from the cache is unrestricted and
# therefore not hidden.
#
# See docs/features/hmis/hmis-restricted-records.md
module Hmis::AuthPolicies::ContextLoaders
  class RestrictedClientLoader
    def initialize(user)
      @user = user
      @hidden_client_ids = Set.new
      @loaded_client_ids = Set.new
      # {enrollment_id => client_id, ...}, restricted clients only
      @client_id_by_enrollment_id = {}
      @loaded_enrollment_ids = Set.new
    end

    def client_hidden?(client_id)
      preload_clients([client_id])
      @hidden_client_ids.include?(client_id)
    end

    def enrollment_hidden?(enrollment_id)
      preload_enrollments([enrollment_id])
      @hidden_client_ids.include?(@client_id_by_enrollment_id[enrollment_id])
    end

    def preload_clients(client_ids)
      new_client_ids = client_ids.compact.uniq - @loaded_client_ids.to_a
      return if new_client_ids.empty?

      @loaded_client_ids.merge(new_client_ids)
      @hidden_client_ids.merge(
        Hmis::RestrictedClientEnrollment.hidden_from(@user).where(client_id: new_client_ids).distinct.pluck(:client_id),
      )
    end

    def preload_enrollments(enrollment_ids)
      new_enrollment_ids = enrollment_ids.compact.uniq - @loaded_enrollment_ids.to_a
      return if new_enrollment_ids.empty?

      @loaded_enrollment_ids.merge(new_enrollment_ids)
      mapping = Hmis::RestrictedClientEnrollment.where(enrollment_id: new_enrollment_ids).pluck(:enrollment_id, :client_id)
      @client_id_by_enrollment_id.merge!(mapping.to_h)

      preload_clients(mapping.map(&:last))
    end
  end
end
