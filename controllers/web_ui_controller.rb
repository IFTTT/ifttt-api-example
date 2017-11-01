# This controller implements the Web UI for this application, including the
# parts needed to act as an OAuth provider.
class WebUIController < ApplicationController
  before do
    # All of the endpoints in this section (except `/oauth/token`) use Sinatra
    # sessions for auth.
    @current_user = User.find(username: session[:username])
  end

  # This endpoint is the front page of the app, which shows a list of applets
  # and lets the user enable or disable them. If the user is logged out, the
  # list of applets won't include statuses.
  get "/" do
    @applets = IftttApi.list_applets(@current_user && @current_user.username)
    erb :index
  end

  # Show the login page.
  get "/log_in" do
    erb :log_in
  end

  # Handle a form submission from the login page, which will just contain a
  # username since accounts in this demo app don't have passwords.
  post "/log_in" do
    username = params[:username] && params[:username].strip

    if username && !username.empty?
      User.find_or_create_by_username(username)
      session[:username] = username
      redirect(session.delete(:after_login) || "/")
    else
      @error = "Please provide a username"
      erb :log_in
    end
  end

  # Handle the user clicking the "Log out" button.
  post "/log_out" do
    session.clear
    redirect "/"
  end

  # Handle the user clicking the "Disable" button on an applet.
  post "/disable" do
    unless @current_user
      redirect "/log_in"
    end

    IftttApi.disable_applet(@current_user.username, params[:applet_id])
    redirect "/"
  end

  # Handle the user clicking the "Enable" button on a disabled applet.
  post "/enable" do
    unless @current_user
      redirect "/log_in"
    end

    IftttApi.enable_applet(@current_user.username, params[:applet_id])
    redirect "/"
  end

  # Log the user in with a temporary JWT issued by the
  # `/mobile_api/get_login_url` endpoint. See that endpoint, defined in
  # `mobile_api_controller.rb`, for more information.
  get "/authorize" do
    token = params[:token]

    unless token
      redirect "/"
    end

    begin
      data, = JWT.decode(token, SESSION_SECRET, true, algorithm: "HS256")

      if Time.now.to_i <= data["expires_at"]
        session[:username] = data["sub"]
      end

      redirect data["redirect_to"]
    rescue JWT::DecodeError
      redirect "/"
    end
  end

  # Show the authorization page for the OAuth flow.
  get "/oauth/authorize" do
    unless @current_user
      session[:after_login] = request.fullpath
      redirect "/log_in"
    end

    session[:oauth_info] = {
      redirect_uri: params[:redirect_uri],
      state: params[:state]
    }
    erb :auth
  end

  # Handle the user clicking the "Authorize" button on the authorization page.
  post "/oauth/authorize" do
    unless @current_user
      session[:after_login] = request.fullpath
      redirect "/log_in"
    end

    oauth_info = session[:oauth_info]

    @current_user.ensure_oauth_code!

    redirect oauth_info[:redirect_uri] +
      "?state=#{oauth_info[:state]}&code=#{@current_user.oauth_code}"
  end

  # Handle the IFTTT server's request to exchange an authorization code for an
  # access token. This endpoint's behavior is determined by the OAuth 2.0 spec.
  post "/oauth/token" do
    headers["Content-Type"] = "application/json; charset=utf-8"

    user = User.find(oauth_code: params[:code])
    user.ensure_oauth_token!

    if user
      {
        access_token: user.oauth_token,
        token_type: "bearer"
      }.to_json
    else
      halt 400, {}, { error: "invalid_grant" }.to_json
    end
  end
end
