<template>
  <header>
    <ul id="dropdown1" class="dropdown-content">
      <li><a href="#!">one</a></li>
      <li><a href="#!">two</a></li>
      <li class="divider"></li>
      <li><a href="#!">three</a></li>
    </ul>
    <nav>
      <div class="nav-wrapper indigo darken-3">
        <a href="#!" class="brand-logo left logo"></a>
        <ul class="right">
          <li><a class="dropdown-trigger" ref="dropdown" href="#!" data-target="dropdown1">Список броней<i
                class="material-icons right">arrow_drop_down</i></a></li>
        </ul>
      </div>
    </nav>
  </header>
</template>

<script>
import M from "materialize-css/dist/js/materialize.min";
export default {
  mounted() {
    M.Dropdown.init(this.$refs.dropdown, {
      constrainWidth: true,
    });
  },

}
</script>

<style lang="scss" scoped></style>
