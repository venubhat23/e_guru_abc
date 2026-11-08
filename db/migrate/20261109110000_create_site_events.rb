class CreateSiteEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :site_events do |t|
      t.string :kind, null: false            # "page_view" | "click"
      t.string :path, null: false
      t.string :visitor_id, null: false      # anonymous cookie token, no PII
      t.string :label                        # clicked element text (clicks only)
      t.string :target                       # clicked link href (clicks only)
      t.string :referrer_host
      t.string :device                       # mobile | tablet | desktop
      t.datetime :created_at, null: false
    end
    add_index :site_events, [ :kind, :created_at ]
    add_index :site_events, [ :created_at, :visitor_id ]
  end
end
