<template>
  <footer class="page-footer indigo darken-3">
    <div class="container black-text row">
      <p class="col s6 white-text">Выбери дату:</p>
      <div class="input-field col s6">
        <i class="material-icons prefix white-text">event</i>
        <input id="icon_prefix" ref="datepicker" class="datepicker white-text center">
      </div>
    </div>
  </footer>
</template>

<script>
import M from "materialize-css/dist/js/materialize.min";
export default {
  data() {
    return {
      date: new Date()
    }
  },
  mounted() {

    const inst = M.Datepicker.init(this.$refs.datepicker, {
      format: 'dd.mm.yy',
      autoClose: true,
      firstDay: 1
    });

    inst.setDate(new Date());
  },
}
</script>

<style lang="scss" scoped></style>
