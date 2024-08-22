enum MoveDirection { left, right, up, down }

extension MoveDirectionDirectionality on MoveDirection {
  bool get isVertical => this == MoveDirection.up || this == MoveDirection.down;
  bool get isHorizontal =>
      this == MoveDirection.left || this == MoveDirection.right;
  MoveDirection get opposite {
    switch (this) {
      case MoveDirection.left:
        return MoveDirection.right;
      case MoveDirection.right:
        return MoveDirection.left;
      case MoveDirection.up:
        return MoveDirection.down;
      case MoveDirection.down:
        return MoveDirection.up;
    }
  }
}
