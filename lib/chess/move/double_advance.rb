module Chess
  module Move
    class DoubleAdvance < Base
      def take
        super do
          state_change[:en_passant_target] = options[:en_passant_target]
        end
      end
    end
  end
end
