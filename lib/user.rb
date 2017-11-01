class User < Sequel::Model
  def self.find_or_create_by_username(username)
    find(username: username) || create(username: username)
  end

  def ensure_oauth_code!
    unless oauth_code
      self.oauth_code = SecureRandom.hex(20)
      save
    end
  end

  def ensure_oauth_token!
    unless oauth_token
      self.oauth_token = SecureRandom.hex(20)
      save
    end
  end

  def ensure_example_app_token!
    unless example_app_token
      self.example_app_token = SecureRandom.hex(20)
      save
    end
  end
end
