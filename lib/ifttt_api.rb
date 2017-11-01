# An API client for the IFTTT API.
module IftttApi
  ApiError = Class.new(RuntimeError)

  def self.list_applets(user_id)
    response = HTTParty.get(
      "https://api.ifttt.com/v1/services/#{SERVICE_ID}/applets",
      headers: { "IFTTT-Service-Key" => SERVICE_KEY },
      query: user_id && { user_id: user_id }
    ).parsed_response

    if response["type"] == "list"
      response["data"]
    else
      raise ApiError, "Unexpected error response: #{response["message"]}"
    end
  end

  def self.disable_applet(user_id, applet_id)
    response = HTTParty.post(
      "https://api.ifttt.com/v1/services/#{SERVICE_ID}/applets/#{applet_id}/disable",
      headers: {
        "Content-Type" => "application/json",
        "IFTTT-Service-Key" => SERVICE_KEY
      },
      body: { user_id: user_id }.to_json
    ).parsed_response

    if response["type"] == "error"
      raise ApiError, "Unexpected error response: #{response["message"]}"
    end
  end

  def self.enable_applet(user_id, applet_id)
    response = HTTParty.post(
      "https://api.ifttt.com/v1/services/#{SERVICE_ID}/applets/#{applet_id}/enable",
      headers: {
        "Content-Type" => "application/json",
        "IFTTT-Service-Key" => SERVICE_KEY
      },
      body: { user_id: user_id }.to_json
    ).parsed_response

    if response["type"] == "error"
      raise ApiError, "Unexpected error response: #{response["message"]}"
    end
  end

  def self.get_user_token(user_id, oauth_token)
    response = HTTParty.post(
      "https://api.ifttt.com/v1/services/#{SERVICE_ID}/user_token",
      headers: {
        "Content-Type" => "application/json",
        "IFTTT-Service-Key" => SERVICE_KEY
      },
      body: { user_id: user_id, token: oauth_token }.to_json
    ).parsed_response

    if response["type"] == "user_token"
      response["user_token"]
    else
      raise ApiError, "Unexpected error response: #{response["message"]}"
    end
  end
end
