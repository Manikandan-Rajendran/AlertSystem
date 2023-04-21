class ApplicationController < ActionController::API
  before_action :authenticate_user
  
  def authenticate_user
    @current_user = nil
    skip_authentication = self.class.const_defined?(:SKIP_AUTHENTICATION) ? self.class::SKIP_AUTHENTICATION : []
    return true if skip_authentication.include?(params[:action])
    token = request.headers['Authorization']&.split&.last
    payload = JWT.decode(token, Rails.application.credentials.config['secret_key_base'.to_sym])&.first
    
    @current_user = Login::User.find_by(id: payload['user_id']) if payload.present?
    
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user.present?
  rescue JWT::DecodeError
    render json: { error: 'Invalid token' }, status: :unprocessable_entity
  end
end
