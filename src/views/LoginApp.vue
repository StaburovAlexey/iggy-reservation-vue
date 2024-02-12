<template>
  <form class="card white">
    <div class="card-content">
      <div class="center">
        <img class="logo-auth" src="../assets/logo-black.png" alt="logo">
      </div>
      <div class="input-field">
        <i class="material-icons prefix">account_circle</i>
        <input id="icon_prefix" type="email" class="validate">
        <label for="icon_prefix">Ваш e-mail</label>
      </div>
      <div class="input-field">
        <i class="material-icons prefix">border_color</i>
        <input id="password" type="password" class="validate">
        <label for="password">Пароль</label>
      </div>
      <div class="center">
        <button class="btn waves-effect waves-light center" type="submit" name="action">Войти
          <i class="material-icons right">send</i>
        </button>
      </div>
    </div>
  </form>
</template>

<script>
export default {

}
</script>

<style lang="scss" scoped></style>
