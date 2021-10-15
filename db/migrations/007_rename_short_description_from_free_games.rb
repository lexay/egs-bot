Sequel.migration do
  change do
    alter_table :free_games do
      rename_column :short_description, :description
    end
  end
end
