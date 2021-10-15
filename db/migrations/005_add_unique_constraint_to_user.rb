Sequel.migration do
  change do
    alter_table(:users) do
      add_unique_constraint :chat_id
    end
  end
end
