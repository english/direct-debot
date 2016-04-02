# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :redirect_flows do
      String :id, null: false, primary_key: true
      String :user_id, null: false
      String :gc_redirect_flow_id, null: false

      foreign_key [:user_id], :users
      index :user_id
    end
  end
end
