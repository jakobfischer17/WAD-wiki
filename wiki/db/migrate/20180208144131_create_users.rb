class CreateUsers < ActiveRecord::Migration[5.0]
 def change
 create_table :users do |t|
 t.string :username
 t.string :password_digest
 t.boolean :edit
 t.timestamps null: false
 end
 User.create(username: "Admin", password: "admin", edit: true)
 end
end