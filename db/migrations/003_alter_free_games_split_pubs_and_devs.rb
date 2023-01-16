Sequel.migration do
  change do
    alter_table(:free_games) do
      rename_column :pubs_n_devs, :publisher
      rename_column :timestamp, :created_at
      rename_column :game_uri, :uri
      add_column :developer, String, :size=>255
    end
  end
end
