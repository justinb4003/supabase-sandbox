import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// GitHub Pages serves the site at /supabase-sandbox/.
export default defineConfig({
  plugins: [react()],
  base: process.env.GITHUB_ACTIONS ? '/supabase-sandbox/' : '/',
})
