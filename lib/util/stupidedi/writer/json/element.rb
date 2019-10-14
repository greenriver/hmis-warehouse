module Stupidedi
  using Refinements

  module Writer
    class Json
      class Element
        attr_reader :node

        def_delegators :node, :definition, :simple?, :composite?, :repeated?, :children
        def_delegators :definition, :code_list, :id, :name

        def initialize(node)
          @node = node
        end

        def reduce(memo, *)
          memo[key] = {
            name: name,
            value: value,
            type: type,
          }
        end

        def type
          if node.composite?
            :composite
          elsif node.repeated?
            :repeated
          else
            :simple
          end
        end

        def key
          id
        end

        class SimpleElement
          attr_reader :node

          def_delegators :node, :definition
          def_delegators :definition, :code_list

          def initialize(node)
            @node = node
          end

          def call(*)
            {
              raw: value, # leaf node
              description: description,
            }
          end

          def description
            return unless definition.respond_to?(:code_list)

            if code_list.try(:internal?)
              code_list.try(:at, value)
            else
              value
            end
          end

          def value
            node.to_s.strip
          end
        end

        class RepeatedElement
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def call
            node.children.map do |c|
              yield(c)
            end
          end
        end

        class CompositeElement
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def call
            node.children.map do |c|
              yield(c)
            end
          end
        end

        class ElementReducer
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def reducer
            if node.simple?
              SimpleElement
            elsif node.repeated?
              RepeatedElement
            elsif node.composite?
              CompositeElement
            else
              SimpleElement
            end.new(node)
          end

          def build
            reducer.call do |children|
              self.class.new(children).build
            end
          end
        end

        def value
          ElementReducer.new(node).build
        end
      end
    end
  end
end
