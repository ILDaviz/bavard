import DefaultTheme from 'vitepress/theme'
import Layout from './Layout.vue'
import './style.css'
import Home from './components/Home.vue'

export default {
  extends: DefaultTheme,
  Layout,
  enhanceApp({ app }) {
    app.component('Home', Home)
  }
}