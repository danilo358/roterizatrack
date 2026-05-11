class ApplicationController < ActionController::API
  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    begin
      @decoded = JsonWebToken.decode(header)
      if @decoded
        @current_user = User.find(@decoded[:user_id])
      else
        render json: { errors: 'Token inválido ou expirado' }, status: :unauthorized and return
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: 'Usuário não encontrado' }, status: :unauthorized and return
    rescue StandardError => e
      render json: { errors: e.message }, status: :unauthorized and return
    end
  end
end
