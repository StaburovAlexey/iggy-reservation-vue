<template>
  <div class="loader" aria-label="loading">
    <span></span>
    <span></span>
    <span></span>
  </div>
</template>

<script setup></script>

<style lang="scss" scoped>
.loader {
  display: inline-flex;
  gap: 6px;
}

.loader span {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #409eff;
  animation: pulse 0.9s infinite alternate;
}

.loader span:nth-child(2) {
  animation-delay: 0.2s;
}
.loader span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes pulse {
  from {
    transform: scale(0.8);
    opacity: 0.6;
  }
  to {
    transform: scale(1.3);
    opacity: 1;
  }
}
</style>
