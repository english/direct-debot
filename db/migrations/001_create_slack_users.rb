Sequel.migration do
  change do
    create_table :slack_users do
      String :slack_user_id, null: false
      String :gc_access_token, null: false

      primary_key [:slack_user_id, :gc_access_token]
    end
  end
end
