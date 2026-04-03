# frozen_string_literal: true

Changeset::Engine.routes.draw do
  root to: "reviews#index"

  resources :reviews, only: %i[index show edit update destroy] do
    member do
      patch :approve
      patch :reject
    end

    resources :review_threads, only: :create, path: "threads"
  end

  resources :review_threads, only: %i[show edit update destroy] do
    member do
      patch :mark_outdated
      patch :resolve
      patch :reopen
    end

    resources :comments, only: %i[create show edit update destroy]
  end
end
