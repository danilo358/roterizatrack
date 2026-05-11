class AddressesController < ApplicationController
  before_action :authorize_request
  before_action :set_address, only: %i[show update destroy]

  def index
    @addresses = Address.all
    render json: @addresses
  end

  def show
    render json: @address
  end

  def create
    @address = Address.new(address_params)
    if @address.save
      render json: @address, status: :created
    else
      render json: @address.errors, status: :unprocessable_entity
    end
  end

  def update
    if @address.update(address_params)
      render json: @address
    else
      render json: @address.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy
  end

  private

  def set_address
    @address = Address.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:street, :number, :city, :state, :zip, :latitude, :longitude, :status, :vehicle_id, :route_id, :sequence_number)
  end
end
