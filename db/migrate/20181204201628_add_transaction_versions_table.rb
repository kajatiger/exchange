class AddTransactionVersionsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_versions do |t|
      t.string :item_type, null: false
      t.uuid :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.jsonb :object
      t.jsonb :object_changes
      t.datetime :created_at
    end
    add_index :transaction_versions, %i[item_type item_id]
  end
end
