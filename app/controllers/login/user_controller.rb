class Login::UserController < ApplicationController

  SKIP_AUTHENTICATION = %w(create_user create_token).freeze

  def create_token
    user =Login::User.find_by(email: params[:email])
    
    if user && user.authenticate(params[:password])
      render json: { token: user.jwt_token }
    else
      render json: { error: 'Invalid email or password' }, status: :unprocessable_entity
    end
  end

  def create_user
    user = Login::User.create!(email: params[:email], password: params[:password])
    render json: { id: user.id, email: user.email }
  rescue ActiveRecord::RecordNotUnique => e
    render json: { error: "user with email #{params[:email]} already exists" }, status: :unprocessable_entity
  end
end
