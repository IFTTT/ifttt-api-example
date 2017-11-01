# This controller is a barebones implementation of the IFTTT Protocol, since
# using the API requires a connectable service.
class IFTTTProtocolController < ApplicationController
  before do
    if service_key
      unless service_key == SERVICE_KEY
        render_error(401, "Invalid channel key")
      end
    elsif bearer_token
      @current_user = User.find(oauth_token: bearer_token)

      unless @current_user
        render_error(401, "Invalid bearer token")
      end
    else
      render_error(401, "Must provide service key or user token")
    end
  end

  after do
    headers["Content-Type"] = "application/json; charset=utf-8"
  end

  get "/status" do
    { ok: true }.to_json
  end

  get "/user/info" do
    {
      data: {
        name: @current_user.username,
        id: @current_user.username
      }
    }.to_json
  end

  post "/test/setup" do
    user = User.find_or_create_by_username("Test User")
    user.ensure_oauth_token!

    {
      data: {
        accessToken: user.oauth_token,
        samples: {
          triggers: {},
          actions: {}
        }
      }
    }.to_json
  end
end
