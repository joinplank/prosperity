class SessionsController < ApplicationController
  before_action :set_session, only: :destroy
  skip_authentication only: %i[new create verify]

  layout "auth"

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      @session = create_session_for(user)
      redirect_to root_path
    else
      flash.now[:alert] = t(".invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @session.destroy
    redirect_to new_session_path, notice: t(".logout_successful")
  end

  def verify
    session = find_session_by_cookie
    if session
      token = JWT.encode({ user_id: session.user.id, exp: ENV["JWT_EXPIRATION_TIME"].to_i }, ENV["JWT_SECRET"], "HS256")
      render json: { valid: true, token: token }, status: :ok
    else
      render json: { valid: false }, status: :unauthorized
    end
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
