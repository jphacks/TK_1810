json.status @status
json.error_message @error
json.data do 
  json.shop do
    json.partial! "shops/shop", shop: @shop
  end
end
