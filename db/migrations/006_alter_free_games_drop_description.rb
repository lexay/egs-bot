Sequel.migration do
  change do
    alter_table(:free_games) do
      drop_column :description
    end
  end
end
