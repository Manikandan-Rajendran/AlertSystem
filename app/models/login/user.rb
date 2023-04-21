class Login::User < ApplicationRecord
  has_many :alerts, class_name: 'Alert'
  has_secure_password

  DEFAULT_JWT_EXPIRY_TIME = 12.hours.to_i
  
  def jwt_token
    payload = { user_id: id , exp: Time.zone.now.to_i + DEFAULT_JWT_EXPIRY_TIME }
    JWT.encode(payload, Rails.application.credentials.config['secret_key_base'.to_sym])
  end
end
