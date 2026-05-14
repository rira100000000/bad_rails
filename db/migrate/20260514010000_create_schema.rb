class CreateSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string  :name, null: false
      t.string  :email, null: false
      t.string  :password_digest, null: false
      t.string  :address
      t.string  :phone
      t.integer :point, default: 0
      t.boolean :admin, default: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :categories do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :books do |t|
      t.string  :title, null: false
      t.string  :author
      t.text    :description
      t.integer :price, null: false, default: 0
      t.string  :status, null: false, default: "listed"
      t.string  :condition
      t.string  :isbn
      t.string  :image_url
      t.references :seller, null: false
      t.references :category
      t.timestamps
    end

    create_table :orders do |t|
      t.references :book, null: false
      t.references :buyer, null: false
      t.string  :status, null: false, default: "pending"
      t.integer :total_price, default: 0
      t.integer :shipping_fee, default: 0
      t.integer :tax, default: 0
      t.string  :payment_method
      t.datetime :paid_at
      t.datetime :shipped_at
      t.datetime :received_at
      t.timestamps
    end

    create_table :reviews do |t|
      t.references :order, null: false
      t.references :reviewer, null: false
      t.references :target_user, null: false
      t.integer :rating, null: false, default: 3
      t.text    :comment
      t.timestamps
    end

    create_table :favorites do |t|
      t.references :user, null: false
      t.references :book, null: false
      t.timestamps
    end

    create_table :notifications do |t|
      t.references :user, null: false
      t.string  :message, null: false
      t.string  :notification_type
      t.integer :target_id
      t.boolean :read, default: false
      t.timestamps
    end
  end
end
