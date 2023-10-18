Sequel.migration do
  change do
    alter_table(:free_games) do
      drop_column :developer
      drop_column :publisher
    end
  end
end
