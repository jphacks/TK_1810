json.status @status
json.error_message @error
json.data do 
  json.coupons do
    json.array! @coupons, partial: 'coupons/coupon', as: :coupon
  end
end
