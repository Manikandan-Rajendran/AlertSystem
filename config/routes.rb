Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace "login" do
    resource "user", only: [] do
      post '', to: 'user#create_user'
      post 'token', to: 'user#create_token'
    end
    
  end

  resource "alert"
end
