Sequel.migration do
  change do
    alter_table(:free_games) do
      add_foreign_key :release_id, :releases
    end
  end
end
