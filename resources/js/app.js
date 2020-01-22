import Vue          from 'vue'
import router       from './routes'
import i18n         from './langs/i18n'
import FontAwesome  from './packages/fontawesome'
import Clipboard    from './packages/clipboard'
import App          from './components/App'

import './components'

const app = new Vue({
    el: '#app',
    components: { App },
    i18n,
    router,
});