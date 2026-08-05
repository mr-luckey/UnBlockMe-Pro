const kBlockSize = 64.0;
const kBlockGap = 4.0;
const kWallWidth = 8.0;
const kBlockToBlockGap = 2 * kBlockGap + kWallWidth;
const kBlockSizeInterval = 2 * kBlockGap + kWallWidth + kBlockSize;
const kSlideDuration = Duration(milliseconds: 150);

extension BlockDimensionsConversion on int {
  double toBlockSize() {
    return kBlockSize + (this - 1) * kBlockSizeInterval;
  }

  double toBlockOffset() {
    return kWallWidth + kBlockGap + this * (kBlockSize + kBlockToBlockGap);
  }

  double toWallOffset() {
    return this * kBlockSizeInterval;
  }

  double toWallSize() {
    return kWallWidth + toWallOffset();
  }

  double toBoardSize() {
    return toWallOffset() + kWallWidth;
  }
}

extension BlockDimensionsReverseConversion on double {
  int blockOffsetToBlockCount() {
    return (this - kWallWidth - kBlockGap) ~/ (kBlockSize + kBlockToBlockGap);
  }

  int wallOffsetToBlockCount() {
    return this ~/ kBlockSizeInterval;
  }

  int blockSizeToBlockCount() {
    return ((this - kBlockSize) ~/ kBlockSizeInterval) + 1;
  }

  int boardSizeToBlockCount() {
    return (this - kWallWidth) ~/ kBlockSizeInterval;
  }
}
