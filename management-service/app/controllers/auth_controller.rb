class AuthController < ApplicationController
  # POST /auth/login
  def login
    @user = User.find_by_email(params[:email])
    if @user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: @user.id)
      time = Time.now + 24.hours.to_i
      render json: { token: token, exp: time.strftime("%m-%d-%Y %H:%M"),
                     user: { id: @user.id, name: @user.name, email: @user.email } }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  # POST /auth/register
  def register
    @user = User.new(register_params)
    if @user.save
      token = JsonWebToken.encode(user_id: @user.id)
      time = Time.now + 24.hours.to_i
      render json: { token: token, exp: time.strftime("%m-%d-%Y %H:%M"),
                     user: { id: @user.id, name: @user.name, email: @user.email } }, status: :created
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end

  def register_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
