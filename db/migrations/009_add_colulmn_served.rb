Sequel.migration do
  change do
    alter_table :free_games do
      add_column :pushed, FalseClass, default: false
    end
  end
end
