Rails.application.routes.draw do
  resources :news_sources do
    collection do
      get :get_news
    end
  end
  
  get 'news_sources/:source_name/story/:story_hash', :to=>'news_sources#get_story'
  mount ActionCable.server => '/cable'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
