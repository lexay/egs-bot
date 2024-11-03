Sequel.migration do
  change do
    alter_table :free_games do
      add_unique_constraint %i[title start_date end_date]
    end
  end
end
