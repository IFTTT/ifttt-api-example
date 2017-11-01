# This controller implements an API to be used by the example mobile apps. They
# need to be able to authenticate with a username and ask for a user token that
# they can then use to make calls to the IFTTT API.
class MobileAPIController < ApplicationController
  # The mobile apps authenticate with a bearer token; for simplicity, we can
  # just give them the same token that we give to IFTTT.
  before do
    if bearer_token
      @current_user = User.find(example_app_token: bearer_token)

      unless @current_user
        render_error(401, "Invalid bearer token")
      end
    end
  end

  after do
    headers["Content-Type"] = "application/json; charset=utf-8"
  end

  # This endpoint lets the mobile app "log in", giving it a token that it can
  # use for future calls to this example app's API.
  post "/log_in" do
    username = params[:username] && params[:username].strip

    if username && !username.empty?
      user = User.find_or_create_by_username(username)
      user.ensure_example_app_token!
      { token: user.example_app_token }.to_json
    else
      render_error(400, "Please provide a username")
    end
  end

  # This endpoint lets the mobile app ask for a bearer token that it can use to
  # talk to the IFTTT API directly. If the user hasn't connected the demo
  # service to their IFTTT account yet, it will return `null`, letting the app
  # know that it should just make unauthenticated calls for now.
  post "/get_ifttt_token" do
    unless @current_user
      render_error(401, "Please provide a bearer token")
    end

    if @current_user.ifttt_user_token
      # If we've already gotten a user token, just return it. In real life we
      # might want to add a `force_refresh` parameter that clients could use
      # to indicate that the stored token isn't working (which could
      # potentially happen; for example, IFTTT might choose to expire issued
      # tokens if the user changes their account password).
      { token: @current_user.ifttt_user_token }.to_json
    elsif !@current_user.oauth_token
      # If the User has no `oauth_token`, it means that they haven't connected
      # the service on the IFTTT side, so we know that trying to do a token
      # exchange would be pointless.
      { token: nil }.to_json
    else
      # If they have an `oauth_token` but no `ifttt_user_token`, it means we
      # can call the token exchange endpoint to get, store, and return a user
      # token.
      token = IftttApi.get_user_token(
        @current_user.username,
        @current_user.oauth_token
      )

      if token
        @current_user.ifttt_user_token = token
        @current_user.save
      end

      { token: token }.to_json
    end
  end

  # This endpoint lets the mobile app ask for a URL which, when accessed in a
  # browser, will automatically log the user into the Web part of the app and
  # then redirect them to the given URL. This is based on a very short-lived
  # token to minimize the potential for abuse. We strongly encourage developers
  # of mobile apps to implement an endpoint like this to ensure that the user
  # doesn't have to log into their website after already being logged into
  # their app.
  post "/get_login_url" do
    unless @current_user
      render_error(401, "Please provide a bearer token")
    end

    redirect_to = URI(params[:redirect_to]) rescue nil

    unless redirect_to
      render_error(422, "Please provide a valid `redirect_to` parameter")
    end

    unless redirect_to.host == "ifttt.com"
      render_error(422, "The `redirect_to` URI's host must be 'ifttt.com'")
    end

    data = {
      sub: @current_user.username,
      redirect_to: redirect_to.to_s,
      # We don't use `exp` so that we can fail in a softer way if the token is
      # expired, considering how short the expire time is. We want to minimize
      # the potential for abuse by only leaving just enough time for the mobile
      # app to send the user to the URL.
      expires_at: Time.now.to_i + 5
    }

    token = JWT.encode(data, SESSION_SECRET, "HS256")

    uri = URI(request.url)
    uri.path = "/authorize"
    uri.query = "token=#{token}"

    { login_url: uri.to_s }.to_json
  end
end
