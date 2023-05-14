
require 'json'

# stan-alone rack app to stub out external apis. To run:
# gem install rackup
# run in docker-compose:
#  ac_hmis_stub:
#    <<: *backend
#    command: bundle exec rackup --host 0.0.0.0 drivers/hmis_external_apis/lib/ac_hmis_stub/config.ru
#    environment:
#      <<: *env
#      VIRTUAL_HOST: hmis-ac-hmis.dev.test
#      VIRTUAL_PORT: 9292
class AcHmisStubApplication
  def call(env)
    handle_request(env['REQUEST_METHOD'], env['PATH_INFO'])
  end

  protected

  def handle_request(method, path)
    case method
    when 'POST'
      case path
      when '/oauth2/token'
        return oauth_success
      when '/api/Referral/ReferralRequest'
        return create_referral_request
      end
    when 'GET'
      case path
      when '/testing'
        return [200, json_headers, [{ test: true }.to_json]]
      end
    end
    bad_request
  end

  def oauth_success
    body = {
      "access_token": '123456abcdef',
      "refresh_token": '123456abcdef',
      "token_type": 'Bearer',
      "expires_in": 3600,
      "scope": 'API_TEST',
    }
    [200, json_headers, [body.to_json]]
  end

  def create_referral_request
    [201, json_headers, [{ referral_request_id: id_seq }.to_json]]
  end

  def json_headers
    { 'Content-Type' => 'application/json' }
  end

  def bad_request
    [400, {}, ['Bad request']]
  end

  def id_seq
    Time.now.to_i.to_s
  end
end

run AcHmisStubApplication.new
