Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name
      Integer :chat_id
      DateTime :timestamp
    end
  end
end
