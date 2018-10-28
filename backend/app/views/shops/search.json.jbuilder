json.status @status
json.error_message @error
json.data do 
  json.shops do
    json.array! @shops, partial: 'shops/shop', as: :shop
  end
end
