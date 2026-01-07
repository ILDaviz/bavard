<script setup>
import DefaultTheme from 'vitepress/theme'
const { Layout } = DefaultTheme
const version = __BAVARD_VERSION__
</script>

<template>
  <Layout>
    <template #nav-bar-title-after>
      <Badge type="tip" :text="`v${version}`" style="margin-left: 10px; transform: translateY(2px);" />
    </template>
  </Layout>
</template>
