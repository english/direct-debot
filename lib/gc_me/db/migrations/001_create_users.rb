Sequel.migration do
  change do
    create_table :users do
      String :id, null: false, primary_key: true
      String :slack_user_id, null: false
      String :gc_access_token, null: false

      index :slack_user_id, unique: true
    end
  end
end
