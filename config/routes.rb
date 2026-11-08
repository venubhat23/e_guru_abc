Rails.application.routes.draw do
  # ---- Public website ----
  root "pages#home"
  get "how-it-works", to: "pages#how_it_works", as: :how_it_works
  resources :occasions, only: :show, path: "gifts"
  get "contact", to: "contacts#new", as: :new_contact
  post "contact", to: "contacts#create", as: :contact
  get "contact/thanks", to: "contacts#thanks", as: :thanks_contact
  resource :vendor_signup, only: %i[show create], path: "become-a-vendor"
  resources :legal_pages, only: :show, path: "legal"
  post "t", to: "site_events#create", as: :site_events
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }, as: :sitemap

  # ---- Payment gateway webhooks (signature verified, idempotent) ----
  post "webhooks/razorpay", to: "webhooks/razorpay#create", as: :razorpay_webhook

  # ---- Authentication ----
  resource :session, only: %i[new create destroy]
  get "login", to: "sessions#new"
  resources :passwords, param: :token, only: %i[new create edit update]
  resource :email_verification, only: %i[new create]
  get "verify-email/:token", to: "email_verifications#show", as: :email_verification_token
  resources :notifications, only: :show do
    post :read_all, on: :collection
  end

  # ---- Platform admin ----
  namespace :admin do
    root "dashboard#show"
    resources :leads, only: %i[index show update] do
      member do
        patch :transition
        post :convert
      end
      resources :notes, only: :create, controller: "lead_notes"
    end
    resources :companies, only: %i[index show]

    # Supply
    resources :vendors, only: %i[index show edit update] do
      member do
        patch :approve
        patch :reject
        patch :suspend
      end
    end
    get "catalogue", to: "catalogue#index", as: :catalogue
    resources :categories, except: :show
    resources :products do
      patch :review, on: :member
    end
    resources :packages
    get "price-preview", to: "price_previews#show", as: :price_preview
    get "offers-matrix", to: "offers_matrix#show", as: :offers_matrix

    # Operations
    resources :bookings, only: %i[index show] do
      member do
        post :auto_assign
        post :manual_assign
        patch :cancel
        patch :confirm_delivery
        patch :dispute
        patch :resolve_dispute
        get :proforma
        get :delivery_report
      end
    end
    resources :assignments, only: %i[index show] do
      member do
        patch :expire
        get :packing_list
        get :labels
      end
    end
    resources :tickets, only: %i[index show update] do
      patch :transition, on: :member
      resources :comments, only: :create, controller: "ticket_comments"
    end

    # Finance
    resources :payments, only: %i[index show] do
      member do
        patch :verify
        patch :reject
      end
    end
    resources :payouts, only: %i[index show] do
      member do
        patch :approve
        patch :pay
      end
    end
    resources :invoices, only: %i[index show]
    resources :reports, only: %i[index show]

    resources :occasions, except: :show
    resources :faqs, except: :show
    resources :legal_pages, except: :show
    resource :settings, only: %i[show update]
    resources :audit_logs, only: :index
    resource :traffic, only: :show, controller: "traffic"
  end

  # ---- HR portal (company tenant) ----
  namespace :hr do
    root "dashboard#show"
    resources :team_members, only: %i[index show]
    resource :company, only: :show
  end

  # ---- Vendor portal (vendor tenant) ----
  namespace :vendor do
    root "dashboard#show"
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
