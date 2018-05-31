class HealthController < ApplicationController
  include HealthAuthorization
  include HealthPatient

end