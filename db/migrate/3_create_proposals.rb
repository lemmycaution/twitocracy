class CreateProposals < ActiveRecord::Migration
  def change
    create_table :proposals do |t|
      
      t.integer     :user_id
      t.text        :subject,             null: false, default: ""
      t.text        :up_tweet,            null: false, default: ""
      t.text        :down_tweet,          null: false, default: ""      
      t.string      :up_tweetid
      t.string      :down_tweetid      
      t.integer     :up_retweet_count,     default: 0
      t.integer     :down_retweet_count,   default: 0
      t.datetime    :started_at
      t.datetime    :finished_at
      t.timestamps
    end

    add_index :proposals, :user_id
    add_index :proposals, :up_tweetid
    add_index :proposals, :up_retweet_count     
    add_index :proposals, :down_tweetid
    add_index :proposals, :down_retweet_count         
    add_index :proposals, :started_at
    add_index :proposals, :finished_at
  end
end
