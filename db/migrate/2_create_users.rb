class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|

      t.string      :suid      
      t.string      :screenname, null: false, default: ""
      t.string      :secret
      t.string      :token
      t.hstore      :meta

      t.timestamps
    end

    add_index :users, :screenname, unique: true  
    add_index :users, :suid, unique: true      
  end
end
