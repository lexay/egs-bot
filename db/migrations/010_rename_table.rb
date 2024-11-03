Sequel.migration do
  change do
    rename_table(:free_games, :games)
  end
end
