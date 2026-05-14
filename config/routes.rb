Rails.application.routes.draw do
  get "dashboards/index"
  # root "page#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  resources :products do
    member do
      post :update_stock # เพิ่มเส้นทาง /products/:id/update_stock
    end
  end

  resources :stock_logs, only: [ :create ] # เน้นไปที่การสร้าง Log จากหน้า Product
  root "dashboards#index" # ให้หน้า Dashboard เป็นหน้าแรกของแอป
end
