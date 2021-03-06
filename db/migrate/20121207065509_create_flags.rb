class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.integer :user_id, :limit => 8
      t.integer :flaggable_id, :limit => 8
      t.string :flaggable_type
      t.timestamps
    end
    add_index :flags, [:user_id, :flaggable_id, :flaggable_type], unique: true
    add_index :flags, [:flaggable_id, :flaggable_type]
    add_index :flags, :user_id
    add_index :flags, :flaggable_id
  end
end
