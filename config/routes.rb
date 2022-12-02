Rails.application.routes.draw do
  resources :news_sources do
    collection do
      get :get_news
      get :get_story
    end
  end
  mount ActionCable.server => '/cable'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
