Rails.application.routes.draw do
  mount Reviewkit::Engine => "/reviewkit"
end
