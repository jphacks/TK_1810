json.merge! coupon.attributes.except(
  "updated_at",
  "created_at", 
  "available_from",
  "expired_at"
)
json.set!("updated_at", coupon.updated_at.strftime("%Y年%m日%d日"))
json.set!("created_at", coupon.created_at.strftime("%Y年%m日%d日"))
json.set!("available_from", coupon.available_from.strftime("%Y年%m日%d日"))
json.set!("expired_at", coupon.expired_at.strftime("%Y年%m日%d日"))
json.status coupon.status
