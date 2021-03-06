class CouponsController < ApplicationController
  def index
    return unless logged_in?
    @coupons = current_user.coupons.order(created_at: :desc)
  end

  def show
    return unless logged_in?
    @coupon = Coupon.find_by(id: params[:id])
    
    if @coupon.nil?
      @status = "error"
      @error = "お店が見つかりませんでした"
      return
    end
  end

  def create
    return unless logged_in?
    
    # set request params
    @coupon = Coupon.new(coupon_params)
    @coupon.user = current_user
    @shop = @coupon.shop
    
    # remove user's past coupon before create
    current_user.coupons
                .where(shop_id: @shop.id)
                .unused
                .not_expired
                .destroy_all

    # set coupon amount
    mean = @coupon.shop.mean_coupon
    instagrammable = 1 + ((@coupon.insta_score-3)/2. + current_user.impact)

    @coupon.amount = mean * instagrammable

    # set available term
    now = Time.current
    @coupon.available_from = now.tomorrow
    @coupon.expired_at = now.tomorrow.next_month
    
    # set random uuid
    @coupon.uuid = SecureRandom.hex(15)

    # create
    unless @coupon.save
      @status = "error"
      @error = @coupon.errors.full_messages.join(", ")
    end
  end

  def apply
    @coupon = Coupon.find_by(uuid: params[:uuid])
    if @coupon.is_used
      @message = '失敗!'
    else
      @coupon.update(is_used: true)
      @message = '成功!'
    end
  end

  private
    def coupon_params
      params.permit(
        :insta_score,
        :photo_url,
        :comment,
        :tweet_url,
        :shop_id,
        :food_category_id,
      )
    end
end
