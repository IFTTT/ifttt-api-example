class ApplicationController < Sinatra::Base
  register Sinatra::SequelExtension

  enable :sessions
  set :session_secret, SESSION_SECRET
  set :database, DATABASE_URL
  set :root, File.expand_path("#{__FILE__}/../..")
  set :views, -> { File.join(root, "views") }

  # These migrations will run automatically at startup if they've never run before.
  migration "Create `users` table" do
    database.create_table :users do
      primary_key :id
      text :username, null: false, length: 255
      text :oauth_code, length: 255
      text :oauth_token, length: 255
      text :mobile_token, length: 255
      text :ifttt_user_token, length: 255
      index :username, unique: true
      index :oauth_code, unique: true
      index :oauth_token, unique: true
      index :mobile_token, unique: true
    end
  end

  migration "Rename `users` mobile_token -> example_app_token" do
    database.alter_table :users do
      rename_column :mobile_token, :example_app_token
    end
  end

  private

  def render_error(code, message)
    halt code, {}, { errors: [{ message: message }] }.to_json
  end

  def service_key
    env["HTTP_IFTTT_SERVICE_KEY"]
  end

  def bearer_token
    header = env["HTTP_AUTHORIZATION"]
    header[/Bearer (.*)/, 1] if header
  end
end
