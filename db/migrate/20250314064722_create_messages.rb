class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :sent_at
      t.string :message_type

      t.timestamps
    end
  end
end
