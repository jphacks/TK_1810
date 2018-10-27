json.status @status
json.error_message @error

json.data do 
  json.coupon do
    json.partial! "coupons/coupon", coupon: @coupon
  end
end
