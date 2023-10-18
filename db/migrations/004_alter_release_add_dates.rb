Sequel.migration do
  change do
    alter_table(:releases) do
      rename_column :timestamp, :created_at
      add_column :start_date, DateTime
      add_column :end_date, DateTime
    end
  end
end
