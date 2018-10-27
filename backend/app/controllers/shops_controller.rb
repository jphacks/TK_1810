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
end
