class ShopsController < ApplicationController
  def index
    @shops = Shop.all
  end

  def show
    @shop = Shop.find_by(id: params[:id])

    if @shop.nil?
      @status = "error"
      @error = "お店が見つかりませんでした"
      return
    end
  end

  def search
    if params[:lat].blank? || params[:long].blank?
      @status = "error"
      @error = "必須パラメータがありません"
      return
    end

    latitude = params[:lat]
    longitude = params[:long]
    distance = 5
    @shops = Shop.near([latitude, longitude], distance, units: :km)

    if @shops.empty?
      @status = "error"
      @error = "お店が見つかりませんでした"
      return
    end
  end
end
