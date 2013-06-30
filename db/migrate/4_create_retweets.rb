class CreateRetweets < ActiveRecord::Migration
  def change
    create_table :retweets do |t|
      
      t.integer     :user_id
      t.integer     :proposal_id
      t.text        :retweetid,             null: false, default: ""
      t.string      :dir,                   null: false, default: ""
      t.timestamps
    end

    add_index :retweets, [:user_id, :proposal_id, :dir]
    add_index :retweets, :retweetid

  end
end
