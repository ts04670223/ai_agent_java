import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from "path"
import tailwindcss from 'tailwindcss'
import autoprefixer from 'autoprefixer'

export default defineConfig({
  plugins: [react()],
  css: {
    postcss: {
      plugins: [
        tailwindcss,
        autoprefixer,
      ],
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(process.cwd(), "./src"),
    },
  },
  server: {
    port: 3000,
    host: '0.0.0.0',
    allowedHosts: ['test6.test'],
    proxy: {
      // 代理到 Kong Gateway，讓 Vite dev mode (port 3000) 也能直接使用 API
      // 無論透過 nginx (port 80) 或直接開 port 3000 都能正常運作
      '/api': {
        target: 'http://192.168.10.10:30000',
        changeOrigin: true,
        timeout: 300000,      // 5 分鐘（AI LLM 推理較慢）
        proxyTimeout: 300000
      }
    },
    watch: {
      usePolling: true
    }
  }
})
