module Enumerable
  def expand(&block)
    Hash[self.zip(self.collect(&block))]
  end

  def pluck(sym)
    collect do |item|
      if item.respond_to? sym
        item.send(sym)
      elsif item.respond_to? :[]
        item[sym]
      end
    end
  end

  def select_by_class(klass)
    select { |obj| klass === obj }
  end

  def detect_by_class(klass)
    select_by_class(klass).first
  end
end
