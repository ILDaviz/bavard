import DefaultTheme from 'vitepress/theme'
import './style.css'
import Home from './components/Home.vue'

export default {
  ...DefaultTheme,
  enhanceApp({ app }) {
    app.component('Home', Home)
  }
}