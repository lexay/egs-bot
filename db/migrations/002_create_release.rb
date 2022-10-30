Sequel.migration do
  change do
    create_table(:releases) do
      primary_key :id
      DateTime :timestamp, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
