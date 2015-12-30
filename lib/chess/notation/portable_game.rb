module Chess
  module Notation
    class PortableGame
      REQUIRED_TAGS = %i(
        event
        site
        date
        round
        white
        black
        result
      )

      OPTIONAL_TAGS = %i(
        annotator
        plycount
        timecontrol
        time
        termination
        mode
        fen
      )

      KNOWN_TAGS = REQUIRED_TAGS + OPTIONAL_TAGS
    end
  end
end
