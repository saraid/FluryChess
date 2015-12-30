class Object
  def try(*args, &block)
    public_send(*args, &block) if respond_to? args.first
  end
end

class NilClass
  def try(*args)
    nil
  end
end
