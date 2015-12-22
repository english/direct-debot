require 'securerandom'

module GCMe
  module DB
    # Interface to the database
    class Store
      # @param db [Sequel::Database]
      def initialize(db)
        @db = db
      end

      def all_users
        @db.from(:users).all
      end

      def find_user(slack_user_id)
        @db.
          from(:users).
          where(slack_user_id: slack_user_id).
          first
      end

      def create_user!(gc_access_token:, slack_user_id:)
        update_count = @db.
          from(:users).
          where(slack_user_id: slack_user_id).
          update(gc_access_token: gc_access_token)

        return unless update_count.zero?

        @db.
          from(:users).
          insert(gc_access_token: gc_access_token, slack_user_id: slack_user_id,
                 id: build_id)
      end

      def count_users!
        @db.from(:users).count
      end

      def create_redirect_flow!(slack_user_id, gc_redirect_flow_id)
        user_id = find_user(slack_user_id).fetch(:id)

        @db.
          from(:redirect_flows).
          insert(id: build_id, user_id: user_id, gc_redirect_flow_id: gc_redirect_flow_id)
      end

      def find_access_token_for_redirect_flow(gc_redirect_flow_id)
        @db.
          select(:gc_access_token).
          from(:users).
          join(:redirect_flows, user_id: :id).
          where(redirect_flows__gc_redirect_flow_id: gc_redirect_flow_id).
          first.
          fetch(:gc_access_token)
      end

      private

      def build_id
        SecureRandom.uuid
      end
    end
  end
end
