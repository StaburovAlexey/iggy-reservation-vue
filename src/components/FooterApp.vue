<template>
  <footer class="page-footer indigo darken-3">
    <div class="container black-text">
      <input type="text" ref="datepicker" class="datepicker white-text">
    </div>
  </footer>
</template>

<script>
import M from "materialize-css/dist/js/materialize.min";
export default {
  mounted() {
    M.Datepicker.init(this.$refs.datepicker, {
      format: 'dd mm yy'
    });
  },
}
</script>

<style lang="scss" scoped></style>
