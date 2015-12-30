module MemoizableMethods
  def memoize(&block)
    @memos ||= {}
    calling_method = (caller.first =~ /`([^']*)'/ && $1).to_sym
    if @memos.key? calling_method
      @memos[calling_method]
    else
      @memos[calling_method] = yield
    end
  end
end
