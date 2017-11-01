require "dotenv"
Dotenv.load

require "sinatra/base"
require "sinatra/sequel"

require "digest"
require "httparty"
require "json"
require "jwt"
require "pry"
require "securerandom"
require "tilt/erb"
require "time"
require "uri"

begin
  DATABASE_URL = ENV.fetch("DATABASE_URL").freeze
  SERVICE_ID = ENV.fetch("SERVICE_ID").freeze
  SERVICE_KEY = ENV.fetch("SERVICE_KEY").freeze
  SESSION_SECRET = ENV.fetch("SESSION_SECRET").freeze

  INVITE_CODE =
    if (invite_url_env = ENV["INVITE_URL"])
      invite_url_env[/code=([^\s]+)/, 1]
    end
rescue KeyError => e
  puts "ERROR: Configuration #{e.message}"
  puts "Run `cp .env.sample .env` and edit `.env` to match your service."
  exit 1
end

require_relative "controllers/application_controller"
require_relative "controllers/ifttt_protocol_controller"
require_relative "controllers/mobile_api_controller"
require_relative "controllers/web_ui_controller"

require_relative "lib/ifttt_api"
require_relative "lib/user"
