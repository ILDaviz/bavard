<script setup>
import DefaultTheme from 'vitepress/theme'
import { onMounted } from 'vue'
import { useData, useRoute } from 'vitepress'

const { Layout } = DefaultTheme
const { frontmatter } = useData()
const route = useRoute()
const version = __BAVARD_VERSION__

function rainGeese() {
  console.log('🦆 Quack! Release the geese!')
  const gooseCount = 40
  const emojis = ['🪿']
  
  for (let i = 0; i < gooseCount; i++) {
    const goose = document.createElement('div')
    goose.innerText = emojis[Math.floor(Math.random() * emojis.length)]
    goose.className = 'goose-emoji'
    goose.style.left = Math.random() * 100 + 'vw'
    const duration = Math.random() * 3 + 2
    goose.style.animationDuration = `${duration}s` 
    goose.style.fontSize = Math.random() * 24 + 16 + 'px'
    document.body.appendChild(goose)

    setTimeout(() => {
      goose.remove()
    }, duration * 1000 + 100)
  }
}

onMounted(() => {
  let clickCount = 0
  let resetTimer = null
  document.addEventListener('click', (e) => {
    const title = e.target.closest('.VPNavBarTitle')
    if (title) {
      const homePaths = ['/', '/index.html', '/bavard/', '/bavard/index.html']
      const isHome = homePaths.includes(route.path)
      if (isHome) {
        clickCount++
        if (resetTimer) clearTimeout(resetTimer)
        resetTimer = setTimeout(() => {
          clickCount = 0
        }, 500)
        if (clickCount >= 5) {
          rainGeese()
          clickCount = 0
        }
      } else {
        console.log('🦆 No geese here, try the homepage! Current path:', route.path)
      }
    }
  })
})
</script>

<template>
  <Layout>
    <template #nav-bar-title-after>
      <Badge type="tip" :text="`v${version}`" style="margin-left: 10px; transform: translateY(2px);" />
    </template>
  </Layout>
</template>
