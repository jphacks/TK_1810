Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  # auth
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  
  # users
  get 'users/current', to: 'users#current'
  get 'users/current/coupons', to: 'coupons#index'
  
  # shops
  get 'shops',     to: 'shops#index'
  get 'shops/:id', to: 'shops#show'

  # coupons
  get 'coupons/:id', to: 'coupons#show'
  put 'coupons', to: 'coupons#create'
end