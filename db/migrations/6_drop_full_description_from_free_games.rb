Sequel.migration do
  change do
    alter_table :free_games do
      drop_column :full_description
    end
  end
end
