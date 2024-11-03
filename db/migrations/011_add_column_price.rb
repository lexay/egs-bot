Sequel.migration do
  change do
    alter_table :games do
      add_column :price, Integer
    end
  end
end
