class Actor
  def can_create?(resource)
    resource.creatable_by?(self)
  end

  def can_read?(resource)
    resource.readable_by?(self)
  end

  def can_update?(resource)
    resource.updatable_by?(self)
  end

  def can_delete?(resource)
    resource.deletable_by?(self)
  end
end
