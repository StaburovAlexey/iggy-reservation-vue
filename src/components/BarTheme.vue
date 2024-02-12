<template>
  <main class="grey darken-3">
    <div class="row">
      <div class="col s2 offset-s5 green center modal-trigger" data-target="modal8">8</div>
    </div>
    <div class="row pull">
      <div class="col s2 offset-s1 green center modal-trigger" data-target="modalPull">Pull</div>

      <div class="col s2 offset-s7 green center modal-trigger" data-target="modal9">9</div>
    </div>
    <div class="row">
      <div class="col s2 offset-s5 green center modal-trigger" data-target="modal10">10</div>
    </div>
    <div class="divider"></div>
    <div class="row">
      <div class="col s3 green center modal-trigger" data-target="modal1">1</div>
      <div class="col s2 offset-s7 green center circle modal-trigger" data-target="modal2">2</div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div class="col s3 green center modal-trigger" data-target="modal3">3</div>
      <div class="col s2 offset-s1 green center circle modal-trigger" data-target="modal4">4</div>
      <div class="col s4 green center modal-trigger" data-target="modal5">5</div>
      <div class="col s2 green center circle modal-trigger" data-target="modal6">6</div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div class="col s2 green center circle modal-trigger" data-target="modal7">7</div>
    </div>
    <div id="modal1" class="modal" ref="modal">
      <div class="modal-content">
      <p class="number-table">1</p>
        <div class="row row-modal">
          <p class="col s6">Время:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="time"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Количество человек:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="person"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Имя:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="name"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Телефон:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="tel"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="waves-effect waves-green btn-flat">Редактировать</button>
        <button type="button" class="waves-effect waves-green btn-flat">Удалить</button>
      </div>
    </div>
    <div id="modal2" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal3" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal4" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal5" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal6" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal7" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal8" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal9" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal10" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modalPull" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header pull</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
  </main>
</template>

<script>
export default {
  mounted() {
    M.AutoInit();
  },

}
</script>

<style lang="scss" scoped></style>
