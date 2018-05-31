class HealthController < ApplicationController
  include HealthAuthorization
  include ClientPathGenerator
  include HealthPatient

end