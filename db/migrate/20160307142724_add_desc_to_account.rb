class AddDescToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :desc, :string
  end
end
