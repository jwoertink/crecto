module Crecto
  module Adapters
    #
    # Adapter module for PostgresSQL
    #
    module Postgres
      extend BaseAdapter

      private def self.update_begin(table_name, fields_values)
        q = ["UPDATE"]
        q.push "#{table_name}"
        q.push "SET"
        q.push "(#{fields_values[:fields]})"
        q.push "="
        q.push "(#{(1..fields_values[:values].size).map { "?" }.join(", ")})"
      end

      private def self.update(conn, changeset)
        fields_values = instance_fields_and_values(changeset.instance)

        q = update_begin(changeset.instance.class.table_name, fields_values)
        q.push "WHERE"
        q.push "#{changeset.instance.class.primary_key_field}=?"
        q.push "RETURNING *"

        execute(conn, position_args(q.join(" ")), fields_values[:values] + [changeset.instance.pkey_value])
      end

      private def self.instance_fields_and_values(query_hash : Hash)
        values = query_hash.values.map do |x|
          if x.is_a?(JSON::Any)
            x.to_json
          elsif x.is_a?(Array)
            x = x.to_json
            x = x.sub(0, "{").sub(x.size - 1, "}")
            x
          else
            x.as(DbValue)
          end
        end
        {fields: query_hash.keys.join(", "), values: values}
      end
    end
  end
end
