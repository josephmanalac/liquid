module Liquid
  class Traversal
    def self.for(node, callbacks = Hash.new(proc {}))
      case node
      when Liquid::Assign
        Assign.new(node, callbacks)
      when Liquid::Case
        Case.new(node, callbacks)
      when Liquid::Condition
        Condition.new(node, callbacks)
      when Liquid::Cycle
        Cycle.new(node, callbacks)
      when Liquid::For
        For.new(node, callbacks)
      when Liquid::If
        If.new(node, callbacks)
      when Liquid::Include
        Include.new(node, callbacks)
      when Liquid::TableRow
        TableRow.new(node, callbacks)
      when Liquid::Variable
        Variable.new(node, callbacks)
      when Liquid::VariableLookup
        VariableLookup.new(node, callbacks)
      else
        new(node, callbacks)
      end
    end

    def initialize(node, callbacks)
      @node = node
      @callbacks = callbacks
    end

    def callback_for(klass, &block)
      cb = block
      cb = ->(node, _) { block[node] } if block.arity.abs == 1
      cb = ->(_, _) { block[] } if block.arity.zero?
      @callbacks[klass] = cb
      self
    end

    def traverse(context = nil)
      children.map do |node|
        item, new_context = @callbacks[node.class][node, context]
        [item, Traversal.for(node, @callbacks).traverse(new_context.nil? ? context : new_context)]
      end
    end

    protected

    def children
      @node.respond_to?(:nodelist) ? Array(@node.nodelist) : []
    end

    class Assign < Traversal
      def children
        [@node.from]
      end
    end

    class Case < Traversal
      def children
        [@node.left] + @node.blocks
      end
    end

    class Condition < Traversal
      def children
        [@node.left, @node.right, @node.child_condition, @node.attachment].compact
      end
    end

    class Cycle < Traversal
      def children
        Array(@node.variables)
      end
    end

    class For < Traversal
      def children
        (super + [@node.limit, @node.from, @node.collection_name]).compact
      end
    end

    class If < Traversal
      def children
        @node.blocks
      end
    end

    class Include < Traversal
      def children
        [@node.template_name_expr, @node.variable_name_expr] + @node.attributes.values
      end
    end

    class TableRow < Traversal
      def children
        super + @node.attributes.values + [@node.collection_name]
      end
    end

    class Variable < Traversal
      def children
        [@node.name] + @node.filters.flatten
      end
    end

    class VariableLookup < Traversal
      def children
        @node.lookups
      end
    end
  end
end
