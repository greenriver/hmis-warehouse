###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Register IDP services with the factory
Idp::ServiceFactory.register_idp_service('zitadel', Idp::ZitadelService)
