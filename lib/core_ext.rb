class Object
  def returning(obj)
    yield obj
    obj
  end
end

