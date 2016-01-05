Just writing a vaguely extensible implementation of basic chess because I feel way out of practice in Ruby.

FluryChess is something I first wrote in Java when I still liked that language. I still have an old copy of my implementation ...somwehere... but it's not worth copying and Ruby is just That Much Cooler anyways.

No idea whether or not I'll continue working on this. It was a weekend project.

## TODO
* [ ] Parse and serialize all the other notational forms available.
  * [ ] Long Algebraic
  * [ ] Reversible Algebraic
  * [ ] Concise Reversible Algebraic
  * [ ] Smith
  * [ ] ICCF Numeric
  * [ ] Coordinate
  * [ ] Extended Position Description (EPD)
* [ ] Handle stalemates.
* [x] Refuse to play moves when the game is over.
* [ ] Manually set a game to "draw accepted" state.
* [ ] Classify opening moves according to the Encyclopedia of Chess Openings (ECO)
* [ ] Implement the Fifty-Move Rule.
* [ ] Add the ability to annotate moves beyond "capture", "check", and "checkmate".
  * [ ] Move evaluations: 
  * [ ] Position evaluation symbols
  * [ ] Nunn Convention
