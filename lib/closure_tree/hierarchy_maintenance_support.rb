module ClosureTree
  module HierarchyMaintenanceSupport

    def self.adapter_for_connection(connection)
      das = WithAdvisoryLock::DatabaseAdapterSupport.new(connection)
      if das.mysql?
        ::ClosureTree::HierarchyMaintenanceSupport::MysqlAdapter
      else
        ::ClosureTree::HierarchyMaintenanceSupport::GenericAdapter
      end
    end

    module MysqlAdapter
      def delete_hierarchy_references
        with_advisory_lock do
          connection.execute <<-SQL.strip_heredoc
          DELETE ht.* FROM #{_ct.quoted_hierarchy_table_name} ht JOIN (
            SELECT DISTINCT descendant_id
            FROM #{_ct.quoted_hierarchy_table_name}
            WHERE ancestor_id = #{_ct.quote(id)}
          ) x ON x.descendant_id = ht.descendant_id
          SQL
        end
      end
    end

    module GenericAdapter
      def delete_hierarchy_references
        with_advisory_lock do
          # PostgreSQL doesn't support INNER JOIN on DELETE, so we can't use that.
          _ct.connection.execute <<-SQL.strip_heredoc
          DELETE FROM #{_ct.quoted_hierarchy_table_name}
          WHERE descendant_id IN (
            SELECT DISTINCT descendant_id
            FROM (SELECT descendant_id
              FROM #{_ct.quoted_hierarchy_table_name}
              WHERE ancestor_id = #{_ct.quote(id)}
            ) AS x )
            OR descendant_id = #{_ct.quote(id)}
          SQL
        end
      end
    end
  end
end
