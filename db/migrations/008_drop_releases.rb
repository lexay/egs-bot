Sequel.migration do
  change do
    alter_table :free_games do
      drop_foreign_key :release_id
    end
    drop_table :releases
  end
end
